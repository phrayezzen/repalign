import { Command, CommandRunner } from 'nest-commander';
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User, UserType } from '../../users/entities/user.entity';
import { CitizenProfile } from '../../users/entities/citizen-profile.entity';
import { Post, PostType } from '../../posts/entities/post.entity';
import { Event, EventType } from '../../congress/entities/event.entity';
import { Petition, PetitionCategory } from '../../congress/entities/petition.entity';

@Injectable()
@Command({
  name: 'seed:simple',
  description: 'Simple seed for basic social features test data',
  options: { isDefault: false },
})
export class SimpleSeedCommand extends CommandRunner {
  private readonly logger = new Logger(SimpleSeedCommand.name);

  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
    @InjectRepository(CitizenProfile) private citizenProfileRepository: Repository<CitizenProfile>,
    @InjectRepository(Post) private postRepository: Repository<Post>,
    @InjectRepository(Event) private eventRepository: Repository<Event>,
    @InjectRepository(Petition) private petitionRepository: Repository<Petition>,
  ) {
    super();
  }

  async run(): Promise<void> {
    this.logger.log('Starting simple seed...');

    try {
      // Create a test user
      const user = await this.createTestUser();

      // Create a test post
      await this.createTestPost(user);

      // Create a test event
      await this.createTestEvent(user);

      // Create a test petition
      await this.createTestPetition(user);

      this.logger.log('Simple seed completed successfully!');
    } catch (error) {
      this.logger.error('Failed to run simple seed', error.stack);
      throw error;
    }
  }

  private async createTestUser(): Promise<User> {
    this.logger.log('Creating test user...');

    // Hash the password before saving
    const hashedPassword = await bcrypt.hash('test_password', 12);

    const userData = {
      email: 'test_user@example.com',
      username: 'test_user',
      displayName: 'Test User',
      userType: UserType.CITIZEN,
      isVerified: true,
      password: hashedPassword,
      location: 'Test City, TS',
    };

    // Delete existing test user if exists
    await this.userRepository.delete({ email: userData.email });

    const user = this.userRepository.create(userData);
    const savedUser = await this.userRepository.save(user);

    // Create citizen profile
    const citizenProfile = this.citizenProfileRepository.create({
      userId: savedUser.id,
      civicEngagementScore: 500,
      isCivicConnector: true,
    });

    await this.citizenProfileRepository.save(citizenProfile);

    return savedUser;
  }

  private async createTestPost(user: User): Promise<void> {
    this.logger.log('Creating test post...');

    // Delete any existing test posts
    await this.postRepository.delete({ authorId: user.id });

    const post = this.postRepository.create({
      authorId: user.id,
      content: 'This is a test post about civic engagement! #democracy #community',
      postType: PostType.TEXT,
      tags: '',
      attachmentUrls: '',
    } as any);

    await this.postRepository.save(post);
  }

  private async createTestEvent(user: User): Promise<void> {
    this.logger.log('Creating test event...');

    // Delete any existing test events
    await this.eventRepository.delete({ creatorUserId: user.id });

    const event = this.eventRepository.create({
      title: 'Test Town Hall Meeting',
      eventDescription: 'A test town hall meeting for community discussion.',
      eventType: EventType.TOWN_HALL,
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 week from now
      location: 'Test Community Center',
      creatorUserId: user.id,
      featuredLegislatorIds: '',
      maxAttendees: 100,
      currentAttendees: 0,
      isVirtual: false,
    } as any);

    await this.eventRepository.save(event);
  }

  private async createTestPetition(user: User): Promise<void> {
    this.logger.log('Creating test petition...');

    // Delete any existing test petitions
    await this.petitionRepository.delete({ creatorId: user.id });

    const petition = this.petitionRepository.create({
      title: 'Test Petition for Better Community Services',
      description: 'This is a test petition to improve community services and infrastructure.',
      targetSignatures: 1000,
      category: PetitionCategory.OTHER,
      creatorId: user.id,
      recipientLegislatorIds: '',
      deadline: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    } as any);

    await this.petitionRepository.save(petition);
  }
}