import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Legislator } from './entities/legislator.entity';
import { LegislatorFollow } from './entities/legislator-follow.entity';
import { CampaignContributor } from './entities/campaign-contributor.entity';
import { Vote } from './entities/vote.entity';
import { CommitteeMembership } from './entities/committee-membership.entity';
import { PressRelease } from './entities/press-release.entity';

export interface FindLegislatorsOptions {
  state?: string;
  chamber?: 'house' | 'senate';
  party?: string;
  search?: string;
  limit?: number;
  offset?: number;
}

@Injectable()
export class LegislatorsService {
  constructor(
    @InjectRepository(Legislator)
    private legislatorRepository: Repository<Legislator>,
    @InjectRepository(LegislatorFollow)
    private legislatorFollowRepository: Repository<LegislatorFollow>,
    @InjectRepository(CampaignContributor)
    private campaignContributorRepository: Repository<CampaignContributor>,
    @InjectRepository(Vote)
    private voteRepository: Repository<Vote>,
    @InjectRepository(CommitteeMembership)
    private committeeMembershipRepository: Repository<CommitteeMembership>,
    @InjectRepository(PressRelease)
    private pressReleaseRepository: Repository<PressRelease>,
  ) {}

  async findAll(options: FindLegislatorsOptions = {}, userId?: string) {
    const {
      state,
      chamber,
      party,
      search,
      limit = 50,
      offset = 0,
    } = options;

    const query = this.legislatorRepository.createQueryBuilder('legislator');

    // Filters
    if (state) {
      query.andWhere('legislator.state = :state', { state: state.toUpperCase() });
    }

    if (chamber) {
      query.andWhere('legislator.chamber = :chamber', { chamber });
    }

    if (party) {
      query.andWhere('legislator.party = :party', { party });
    }

    if (search) {
      query.andWhere(
        '(legislator.firstName ILIKE :search OR legislator.lastName ILIKE :search)',
        { search: `%${search}%` },
      );
    }

    // Pagination and ordering
    query
      .orderBy('legislator.lastName', 'ASC')
      .addOrderBy('legislator.firstName', 'ASC')
      .skip(offset)
      .take(limit);

    const [legislators, total] = await query.getManyAndCount();

    // Get follow status for authenticated user
    let followedLegislatorIds: Set<string> = new Set();
    if (userId) {
      const follows = await this.legislatorFollowRepository.find({
        where: { userId },
        select: ['legislatorId'],
      });
      followedLegislatorIds = new Set(follows.map(f => f.legislatorId));
    }

    // Add isFollowing flag to each legislator
    const legislatorsWithFollowStatus = legislators.map(legislator => ({
      ...legislator,
      isFollowing: followedLegislatorIds.has(legislator.id),
    }));

    return {
      legislators: legislatorsWithFollowStatus,
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    };
  }

  async findOne(id: string, userId?: string): Promise<any> {
    const legislator = await this.legislatorRepository.findOne({
      where: { id },
    });

    if (!legislator) {
      throw new NotFoundException(`Legislator with ID ${id} not found`);
    }

    // Get follow status
    let isFollowing = false;
    if (userId) {
      const follow = await this.legislatorFollowRepository.findOne({
        where: { legislatorId: id, userId },
      });
      isFollowing = !!follow;
    }

    // Get top 5 donors
    const topDonors = await this.campaignContributorRepository.find({
      where: { legislatorId: id },
      order: { amount: 'DESC' },
      take: 5,
    });

    // Get recent 10 votes with bill info
    const recentVotes = await this.voteRepository.find({
      where: { legislatorId: id },
      relations: ['bill'],
      order: { timestamp: 'DESC' },
      take: 10,
    });

    // Get committees
    const committees = await this.committeeMembershipRepository.find({
      where: { legislatorId: id },
      order: { role: 'ASC' }, // Chairs first
    });

    return {
      ...legislator,
      isFollowing,
      committees: committees.map(c => ({
        id: c.id,
        committeeName: c.committeeName,
        role: c.role,
      })),
      topDonors: topDonors.map(donor => ({
        id: donor.id,
        name: donor.contributorName,
        type: donor.contributorType,
        amount: donor.amount,
        formattedAmount: donor.formattedAmount,
        date: new Date(donor.date).toISOString(),
      })),
      recentVotes: recentVotes.map(vote => ({
        id: vote.id,
        billId: vote.billId,
        billTitle: vote.bill?.title || 'Unknown Bill',
        billNumber: vote.bill?.congressBillId,
        position: vote.position,
        timestamp: vote.timestamp.toISOString(),
        // Mock alignment for now - this would be calculated based on user preferences
        aligned: Math.random() > 0.3, // ~70% aligned
      })),
    };
  }

  async findByBioguideId(bioguideId: string): Promise<Legislator> {
    return this.legislatorRepository.findOne({
      where: { bioguideId },
    });
  }

  async findByState(state: string): Promise<Legislator[]> {
    return this.legislatorRepository.find({
      where: { state: state.toUpperCase() },
      order: {
        chamber: 'ASC', // Senators first
        district: 'ASC',
      },
    });
  }

  async getStats() {
    const total = await this.legislatorRepository.count();
    const senators = await this.legislatorRepository.count({
      where: { chamber: 'senate' },
    });
    const representatives = await this.legislatorRepository.count({
      where: { chamber: 'house' },
    });

    const partyStats = await this.legislatorRepository
      .createQueryBuilder('legislator')
      .select('legislator.party', 'party')
      .addSelect('COUNT(*)', 'count')
      .groupBy('legislator.party')
      .getRawMany();

    return {
      total,
      senators,
      representatives,
      byParty: partyStats.reduce((acc, stat) => {
        acc[stat.party] = parseInt(stat.count);
        return acc;
      }, {}),
    };
  }

  async followLegislator(legislatorId: string, userId: string): Promise<{ message: string; followerCount: number }> {
    const legislator = await this.legislatorRepository.findOne({
      where: { id: legislatorId },
    });

    if (!legislator) {
      throw new NotFoundException(`Legislator with ID ${legislatorId} not found`);
    }

    // Check if already following
    const existingFollow = await this.legislatorFollowRepository.findOne({
      where: { legislatorId, userId },
    });

    if (existingFollow) {
      throw new ConflictException('You are already following this legislator');
    }

    // Create follow
    const follow = this.legislatorFollowRepository.create({
      legislatorId,
      userId,
    });

    await this.legislatorFollowRepository.save(follow);

    // Increment follower count
    await this.legislatorRepository.increment(
      { id: legislatorId },
      'followerCount',
      1,
    );

    const updatedLegislator = await this.legislatorRepository.findOne({
      where: { id: legislatorId },
    });

    return {
      message: 'Successfully followed legislator',
      followerCount: updatedLegislator.followerCount,
    };
  }

  async unfollowLegislator(legislatorId: string, userId: string): Promise<{ message: string; followerCount: number }> {
    const legislator = await this.legislatorRepository.findOne({
      where: { id: legislatorId },
    });

    if (!legislator) {
      throw new NotFoundException(`Legislator with ID ${legislatorId} not found`);
    }

    const follow = await this.legislatorFollowRepository.findOne({
      where: { legislatorId, userId },
    });

    if (!follow) {
      throw new NotFoundException('You are not following this legislator');
    }

    await this.legislatorFollowRepository.remove(follow);

    // Decrement follower count
    await this.legislatorRepository.decrement(
      { id: legislatorId },
      'followerCount',
      1,
    );

    const updatedLegislator = await this.legislatorRepository.findOne({
      where: { id: legislatorId },
    });

    return {
      message: 'Successfully unfollowed legislator',
      followerCount: updatedLegislator.followerCount,
    };
  }

  async getDonors(
    legislatorId: string,
    options: { limit?: number; offset?: number; type?: string } = {},
  ) {
    const { limit = 50, offset = 0, type } = options;

    const query = this.campaignContributorRepository
      .createQueryBuilder('contributor')
      .where('contributor.legislator_id = :legislatorId', { legislatorId });

    // Filter by type
    if (type && type !== 'all') {
      if (type === 'individual') {
        query.andWhere('contributor.contributor_type = :type', {
          type: 'Individual',
        });
      } else if (type === 'pac') {
        query.andWhere(
          'contributor.contributor_type IN (:...types)',
          { types: ['PAC', 'Super PAC'] },
        );
      }
    }

    query
      .orderBy('contributor.amount', 'DESC')
      .skip(offset)
      .take(limit);

    const [donors, total] = await query.getManyAndCount();

    return {
      donors: donors.map(donor => ({
        id: donor.id,
        name: donor.contributorName,
        type: donor.contributorType,
        amount: donor.amount,
        formattedAmount: donor.formattedAmount,
        date: new Date(donor.date).toISOString(),
      })),
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    };
  }

  async getVotes(
    legislatorId: string,
    options: { limit?: number; offset?: number } = {},
  ) {
    const { limit = 50, offset = 0 } = options;

    const query = this.voteRepository
      .createQueryBuilder('vote')
      .leftJoinAndSelect('vote.bill', 'bill')
      .where('vote.legislator_id = :legislatorId', { legislatorId })
      .orderBy('vote.timestamp', 'DESC')
      .skip(offset)
      .take(limit);

    const [votes, total] = await query.getManyAndCount();

    return {
      votes: votes.map(vote => ({
        id: vote.id,
        billId: vote.billId,
        billTitle: vote.bill?.title || 'Unknown Bill',
        billNumber: vote.bill?.congressBillId,
        position: vote.position,
        timestamp: vote.timestamp.toISOString(),
        // Mock alignment for now - this would be calculated based on user preferences
        aligned: Math.random() > 0.3, // ~70% aligned
      })),
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    };
  }

  async getPressReleases(
    legislatorId: string,
    options: { limit?: number; offset?: number } = {},
  ) {
    const { limit = 50, offset = 0 } = options;

    const query = this.pressReleaseRepository
      .createQueryBuilder('press')
      .where('press.legislator_id = :legislatorId', { legislatorId })
      .orderBy('press.published_at', 'DESC')
      .skip(offset)
      .take(limit);

    const [pressReleases, total] = await query.getManyAndCount();

    return {
      pressReleases: pressReleases.map(press => ({
        id: press.id,
        title: press.title,
        description: press.description,
        thumbnailUrl: press.thumbnailUrl,
        publishedAt: press.publishedAt.toISOString(),
      })),
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    };
  }
}