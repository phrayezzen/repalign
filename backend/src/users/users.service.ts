import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserType } from './entities/user.entity';
import { CitizenProfile } from './entities/citizen-profile.entity';
import { LegislatorProfile } from './entities/legislator-profile.entity';
import { Follow } from '../posts/entities/follow.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(CitizenProfile)
    private citizenProfileRepository: Repository<CitizenProfile>,
    @InjectRepository(LegislatorProfile)
    private legislatorProfileRepository: Repository<LegislatorProfile>,
    @InjectRepository(Follow)
    private followRepository: Repository<Follow>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user = this.usersRepository.create(createUserDto);
    return this.usersRepository.save(user);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    search?: string,
    userType?: UserType,
  ): Promise<{ users: User[]; total: number; totalPages: number }> {
    const query = this.usersRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.citizenProfile', 'citizenProfile')
      .leftJoinAndSelect('user.legislatorProfile', 'legislatorProfile');

    if (search) {
      query.where(
        'user.username ILIKE :search OR user.displayName ILIKE :search OR user.location ILIKE :search',
        { search: `%${search}%` },
      );
    }

    if (userType) {
      query.andWhere('user.userType = :userType', { userType });
    }

    const [users, total] = await query
      .orderBy('user.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      users,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id },
      relations: ['citizenProfile', 'legislatorProfile'],
    });
  }

  async findByUsername(username: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { username },
      relations: ['citizenProfile', 'legislatorProfile'],
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email },
      relations: ['citizenProfile', 'legislatorProfile'],
    });
  }

  async findByUsernameOrEmail(usernameOrEmail: string, email?: string): Promise<User | null> {
    const query = this.usersRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.citizenProfile', 'citizenProfile')
      .leftJoinAndSelect('user.legislatorProfile', 'legislatorProfile');

    if (email) {
      // When both username and email are provided separately
      query.where('user.username = :username OR user.email = :email', {
        username: usernameOrEmail,
        email,
      });
    } else {
      // When usernameOrEmail could be either
      query.where('user.username = :usernameOrEmail OR user.email = :usernameOrEmail', {
        usernameOrEmail,
      });
    }

    return query.getOne();
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.findById(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    Object.assign(user, updateUserDto);
    return this.usersRepository.save(user);
  }

  async updateLastActive(id: string): Promise<void> {
    await this.usersRepository.update(id, { lastActive: new Date() });
  }

  async remove(id: string): Promise<void> {
    const result = await this.usersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('User not found');
    }
  }

  // Profile-specific methods
  async createCitizenProfile(userId: string): Promise<CitizenProfile> {
    const citizenProfile = this.citizenProfileRepository.create({ userId });
    return this.citizenProfileRepository.save(citizenProfile);
  }

  async createLegislatorProfile(
    userId: string,
    profileData: Partial<LegislatorProfile>,
  ): Promise<LegislatorProfile> {
    const legislatorProfile = this.legislatorProfileRepository.create({
      userId,
      ...profileData,
    });
    return this.legislatorProfileRepository.save(legislatorProfile);
  }

  async updateCitizenProfile(
    userId: string,
    profileData: Partial<CitizenProfile>,
  ): Promise<CitizenProfile> {
    const profile = await this.citizenProfileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Citizen profile not found');
    }

    Object.assign(profile, profileData);

    // Update level if score changed
    if (profileData.civicEngagementScore !== undefined) {
      profile.updateLevel();
    }

    return this.citizenProfileRepository.save(profile);
  }

  async updateLegislatorProfile(
    userId: string,
    profileData: Partial<LegislatorProfile>,
  ): Promise<LegislatorProfile> {
    const profile = await this.legislatorProfileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Legislator profile not found');
    }

    Object.assign(profile, profileData);
    return this.legislatorProfileRepository.save(profile);
  }

  // Search methods
  async searchUsers(
    query: string,
    userType?: UserType,
    limit: number = 20,
  ): Promise<User[]> {
    const searchQuery = this.usersRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.citizenProfile', 'citizenProfile')
      .leftJoinAndSelect('user.legislatorProfile', 'legislatorProfile')
      .where(
        'user.username ILIKE :query OR user.displayName ILIKE :query OR user.location ILIKE :query',
        { query: `%${query}%` },
      );

    if (userType) {
      searchQuery.andWhere('user.userType = :userType', { userType });
    }

    return searchQuery
      .orderBy('user.followersCount', 'DESC')
      .take(limit)
      .getMany();
  }

  async getLegislators(): Promise<User[]> {
    return this.usersRepository.find({
      where: { userType: UserType.LEGISLATOR },
      relations: ['legislatorProfile'],
      order: { displayName: 'ASC' },
    });
  }

  async getLegislatorByBioguideId(bioguideId: string): Promise<User | null> {
    return this.usersRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.legislatorProfile', 'legislatorProfile')
      .where('legislatorProfile.bioguideId = :bioguideId', { bioguideId })
      .getOne();
  }

  // Follow functionality
  async followUser(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestException('Cannot follow yourself');
    }

    const [follower, following] = await Promise.all([
      this.findById(followerId),
      this.findById(followingId),
    ]);

    if (!follower || !following) {
      throw new NotFoundException('User not found');
    }

    const existingFollow = await this.followRepository.findOne({
      where: { followerId, followingId },
    });

    if (existingFollow) {
      return { message: 'Already following this user' };
    }

    const follow = this.followRepository.create({
      followerId,
      followingId,
    });

    await this.followRepository.save(follow);

    // Update follower counts
    await this.updateFollowerCounts(followingId);

    return { message: 'User followed successfully' };
  }

  async unfollowUser(followerId: string, followingId: string) {
    const follow = await this.followRepository.findOne({
      where: { followerId, followingId },
    });

    if (follow) {
      await this.followRepository.remove(follow);
      await this.updateFollowerCounts(followingId);
    }

    return { message: 'User unfollowed successfully' };
  }

  async getFollowerCount(userId: string) {
    const count = await this.followRepository.count({
      where: { followingId: userId },
    });

    return { count };
  }

  async isFollowing(followerId: string, followingId: string) {
    const follow = await this.followRepository.findOne({
      where: { followerId, followingId },
    });

    return { isFollowing: !!follow };
  }

  private async updateFollowerCounts(userId: string) {
    const followerCount = await this.followRepository.count({
      where: { followingId: userId },
    });

    await this.usersRepository.update(userId, {
      followersCount: followerCount,
    });
  }
}