import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Legislator } from './entities/legislator.entity';

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
  ) {}

  async findAll(options: FindLegislatorsOptions = {}) {
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

    return {
      legislators,
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    };
  }

  async findOne(id: string): Promise<Legislator> {
    return this.legislatorRepository.findOne({
      where: { id },
    });
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
}