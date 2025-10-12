import { Command, CommandRunner } from 'nest-commander';
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserType } from '../../users/entities/user.entity';
import { CitizenProfile } from '../../users/entities/citizen-profile.entity';
import { LegislatorProfile } from '../../users/entities/legislator-profile.entity';
import { Post, PostType } from '../../posts/entities/post.entity';
import { Comment } from '../../posts/entities/comment.entity';
import { Like } from '../../posts/entities/like.entity';
import { Follow } from '../../posts/entities/follow.entity';
import { Media, MediaType } from '../../posts/entities/media.entity';
import { Event, EventType } from '../../congress/entities/event.entity';
import { EventParticipant, ParticipantStatus } from '../../congress/entities/event-participant.entity';
import { Petition, PetitionCategory, PetitionStatus } from '../../congress/entities/petition.entity';
import { PetitionSignature } from '../../congress/entities/petition-signature.entity';
import { Legislator } from '../../congress/entities/legislator.entity';

@Injectable()
@Command({
  name: 'seed:social',
  description: 'Seed database with test data for social features',
  options: { isDefault: false },
})
export class SeedSocialFeaturesCommand extends CommandRunner {
  private readonly logger = new Logger(SeedSocialFeaturesCommand.name);

  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
    @InjectRepository(CitizenProfile) private citizenProfileRepository: Repository<CitizenProfile>,
    @InjectRepository(LegislatorProfile) private legislatorProfileRepository: Repository<LegislatorProfile>,
    @InjectRepository(Post) private postRepository: Repository<Post>,
    @InjectRepository(Comment) private commentRepository: Repository<Comment>,
    @InjectRepository(Like) private likeRepository: Repository<Like>,
    @InjectRepository(Follow) private followRepository: Repository<Follow>,
    @InjectRepository(Media) private mediaRepository: Repository<Media>,
    @InjectRepository(Event) private eventRepository: Repository<Event>,
    @InjectRepository(EventParticipant) private eventParticipantRepository: Repository<EventParticipant>,
    @InjectRepository(Petition) private petitionRepository: Repository<Petition>,
    @InjectRepository(PetitionSignature) private petitionSignatureRepository: Repository<PetitionSignature>,
    @InjectRepository(Legislator) private legislatorRepository: Repository<Legislator>,
  ) {
    super();
  }

  async run(): Promise<void> {
    this.logger.log('Starting social features seed...');

    try {
      // Clear existing data (in dependency order)
      await this.clearExistingData();

      // Create test users
      const users = await this.createTestUsers();

      // Create events
      const events = await this.createTestEvents(users);

      // Create petitions
      const petitions = await this.createTestPetitions(users);

      // Create posts
      const posts = await this.createTestPosts(users, events, petitions);

      // Create media
      await this.createTestMedia(users, posts);

      // Create engagement (comments, likes, follows)
      await this.createTestEngagement(users, posts);

      // Create event participants
      await this.createTestEventParticipants(users, events);

      // Create petition signatures
      await this.createTestPetitionSignatures(users, petitions);

      this.logger.log('Social features seed completed successfully!');
    } catch (error) {
      this.logger.error('Failed to seed social features', error.stack);
      throw error;
    }
  }

  private async clearExistingData(): Promise<void> {
    this.logger.log('Clearing existing test data...');

    // Delete in reverse dependency order - use query builder to avoid empty criteria error
    await this.petitionSignatureRepository.createQueryBuilder().delete().execute();
    await this.eventParticipantRepository.createQueryBuilder().delete().execute();
    await this.mediaRepository.createQueryBuilder().delete().execute();
    await this.likeRepository.createQueryBuilder().delete().execute();
    await this.commentRepository.createQueryBuilder().delete().execute();
    await this.followRepository.createQueryBuilder().delete().execute();
    await this.postRepository.createQueryBuilder().delete().execute();
    await this.petitionRepository.createQueryBuilder().delete().execute();
    await this.eventRepository.createQueryBuilder().delete().execute();
    await this.citizenProfileRepository.createQueryBuilder().delete().execute();
    await this.legislatorProfileRepository.createQueryBuilder().delete().execute();

    // Keep users that might be referenced by other entities, just delete test users
    await this.userRepository.createQueryBuilder()
      .delete()
      .where('email LIKE :pattern', { pattern: 'test_%' })
      .execute();
  }

  private async createTestUsers(): Promise<User[]> {
    this.logger.log('Creating test users...');

    const testUsers = [
      {
        email: 'test_citizen1@example.com',
        username: 'alice_civic',
        displayName: 'Alice Johnson',
        type: UserType.CITIZEN,
        location: 'San Francisco, CA',
        isVerified: true,
      },
      {
        email: 'test_citizen2@example.com',
        username: 'bob_activist',
        displayName: 'Bob Smith',
        type: UserType.CITIZEN,
        location: 'New York, NY',
        isVerified: true,
      },
      {
        email: 'test_citizen3@example.com',
        username: 'carol_voter',
        displayName: 'Carol Martinez',
        type: UserType.CITIZEN,
        location: 'Austin, TX',
        isVerified: false,
      },
    ];

    const users: User[] = [];

    for (const userData of testUsers) {
      const user = this.userRepository.create({
        email: userData.email,
        username: userData.username,
        displayName: userData.displayName,
        userType: userData.type,
        isVerified: userData.isVerified,
        password: 'hashed_password_here', // In real app, this would be properly hashed
        location: userData.location,
      });

      const savedUser = await this.userRepository.save(user);

      // Create citizen profile
      const citizenProfile = this.citizenProfileRepository.create({
        userId: savedUser.id,
        civicEngagementScore: Math.floor(Math.random() * 1000),
        isCivicConnector: userData.isVerified,
      });

      await this.citizenProfileRepository.save(citizenProfile);
      users.push(savedUser);
    }

    return users;
  }

  private async createTestEvents(users: User[]): Promise<Event[]> {
    this.logger.log('Creating test events...');

    // Get some real legislators for featured speakers
    const legislators = await this.legislatorRepository.find({ take: 5 });

    const eventData = [
      {
        title: 'Climate Action Town Hall',
        eventDescription: 'Join us for a community discussion on local climate initiatives and how you can get involved in making a difference.',
        eventType: EventType.TOWN_HALL,
        date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 week from now
        location: 'City Hall Auditorium, San Francisco, CA',
        maxAttendees: 200,
        isVirtual: false,
        featuredLegislatorIds: legislators.slice(0, 2).map(l => l.id),
      },
      {
        title: 'Virtual Healthcare Reform Debate',
        eventDescription: 'A moderated debate between local representatives discussing proposed healthcare reforms and their impact on our community.',
        eventType: EventType.DEBATE,
        date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 2 weeks from now
        location: 'Online Event',
        maxAttendees: 500,
        isVirtual: true,
        virtualLink: 'https://zoom.us/j/example123',
        featuredLegislatorIds: legislators.slice(1, 3).map(l => l.id),
      },
      {
        title: 'Education Committee Hearing',
        eventDescription: 'Public hearing on the proposed education budget for the upcoming fiscal year. Community input welcomed.',
        eventType: EventType.COMMITTEE_HEARING,
        date: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000), // 3 weeks from now
        location: 'State Capitol Building, Room 101',
        maxAttendees: 100,
        isVirtual: false,
        featuredLegislatorIds: legislators.slice(2, 4).map(l => l.id),
      },
    ];

    const events: Event[] = [];

    for (const data of eventData) {
      const event = this.eventRepository.create({
        ...data,
        creatorUserId: users[Math.floor(Math.random() * users.length)].id,
      });

      const savedEvent = await this.eventRepository.save(event);
      events.push(savedEvent);
    }

    return events;
  }

  private async createTestPetitions(users: User[]): Promise<Petition[]> {
    this.logger.log('Creating test petitions...');

    const petitionData = [
      {
        title: 'Increase Funding for Public Schools',
        description: 'We demand increased funding for public education to ensure every child has access to quality learning resources, smaller class sizes, and modern facilities. Our schools are underfunded and our children deserve better.',
        targetSignatures: 1000,
        category: PetitionCategory.EDUCATION,
        targetAudience: 'State Legislature',
        deadline: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 60 days from now
      },
      {
        title: 'Green Energy Initiative',
        description: 'Support renewable energy infrastructure in our community. We call for investment in solar and wind energy projects to create jobs and reduce our carbon footprint for future generations.',
        targetSignatures: 2500,
        category: PetitionCategory.ENVIRONMENT,
        targetAudience: 'City Council',
        deadline: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000), // 45 days from now
      },
      {
        title: 'Universal Healthcare Access',
        description: 'Every person deserves access to affordable, quality healthcare. Support legislation that expands healthcare coverage and reduces medical costs for working families.',
        targetSignatures: 5000,
        category: PetitionCategory.HEALTHCARE,
        targetAudience: 'Congress',
        deadline: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days from now
      },
    ];

    const petitions: Petition[] = [];

    for (const data of petitionData) {
      const petition = this.petitionRepository.create({
        ...data,
        creatorId: users[Math.floor(Math.random() * users.length)].id,
      });

      const savedPetition = await this.petitionRepository.save(petition);
      petitions.push(savedPetition);
    }

    return petitions;
  }

  private async createTestPosts(users: User[], events: Event[], petitions: Petition[]): Promise<Post[]> {
    this.logger.log('Creating test posts...');

    const postData = [
      {
        content: 'Just attended an amazing town hall about climate action! The solutions being proposed are really encouraging. We all need to get involved in our local environmental initiatives. 🌱 #ClimateAction #CommunityFirst',
        postType: PostType.TEXT,
        tags: ['ClimateAction', 'CommunityFirst', 'Environment'],
      },
      {
        content: 'Check out this important healthcare reform debate happening next week. These discussions directly impact our families and communities.',
        postType: PostType.SHARED_EVENT,
        sharedEventId: events[1].id,
        tags: ['Healthcare', 'Debate', 'Community'],
      },
      {
        content: 'Our kids deserve better! Please sign this petition to increase school funding. Quality education is the foundation of a strong democracy.',
        postType: PostType.SHARED_PETITION,
        sharedPetitionId: petitions[0].id,
        tags: ['Education', 'Schools', 'FundOurFuture'],
      },
      {
        content: 'Had a great conversation with my representative today about renewable energy policies. It\'s encouraging to see elected officials listening to constituent concerns. Democracy works when we participate! 🗳️',
        postType: PostType.TEXT,
        tags: ['Democracy', 'RenewableEnergy', 'CivicEngagement'],
      },
      {
        content: 'The climate action town hall was packed! So inspiring to see our community coming together for environmental justice. Here are some photos from the event.',
        postType: PostType.IMAGE,
        tags: ['ClimateAction', 'Community', 'TownHall'],
        attachmentUrls: ['https://example.com/townhall1.jpg', 'https://example.com/townhall2.jpg'],
      },
    ];

    const posts: Post[] = [];

    for (const data of postData) {
      const post = this.postRepository.create({
        ...data,
        authorId: users[Math.floor(Math.random() * users.length)].id,
      });

      const savedPost = await this.postRepository.save(post);
      posts.push(savedPost);
    }

    return posts;
  }

  private async createTestMedia(users: User[], posts: Post[]): Promise<void> {
    this.logger.log('Creating test media...');

    const mediaData = [
      {
        url: 'https://example.com/townhall-photo1.jpg',
        mediaType: MediaType.IMAGE,
        mimeType: 'image/jpeg',
        fileSize: 2048576, // 2MB
        originalFilename: 'townhall-photo1.jpg',
        alt: 'Community members at climate action town hall',
        caption: 'Packed auditorium for climate action discussion',
        width: 1920,
        height: 1080,
        associatedPostId: posts[4].id, // The image post
      },
      {
        url: 'https://example.com/debate-recording.mp4',
        mediaType: MediaType.VIDEO,
        mimeType: 'video/mp4',
        fileSize: 52428800, // 50MB
        originalFilename: 'healthcare-debate.mp4',
        alt: 'Healthcare reform debate recording',
        caption: 'Full recording of healthcare reform debate',
        width: 1280,
        height: 720,
        duration: 3600, // 1 hour
      },
      {
        url: 'https://example.com/petition-flyer.pdf',
        mediaType: MediaType.DOCUMENT,
        mimeType: 'application/pdf',
        fileSize: 1048576, // 1MB
        originalFilename: 'education-funding-flyer.pdf',
        alt: 'Education funding petition informational flyer',
        caption: 'Key facts about education funding needs',
      },
    ];

    for (const data of mediaData) {
      const media = this.mediaRepository.create({
        ...data,
        uploadedBy: users[Math.floor(Math.random() * users.length)].id,
      });

      await this.mediaRepository.save(media);
    }
  }

  private async createTestEngagement(users: User[], posts: Post[]): Promise<void> {
    this.logger.log('Creating test engagement (comments, likes, follows)...');

    // Create comments
    const commentData = [
      'This is so important! Thanks for sharing.',
      'I completely agree. We need more community involvement.',
      'Great points raised in this discussion.',
      'How can I get more involved in local politics?',
      'This event changed my perspective on civic engagement.',
      'We need more young people participating in democracy.',
    ];

    for (const post of posts) {
      // Add 2-5 random comments per post
      const numComments = Math.floor(Math.random() * 4) + 2;
      for (let i = 0; i < numComments; i++) {
        const comment = this.commentRepository.create({
          content: commentData[Math.floor(Math.random() * commentData.length)],
          postId: post.id,
          authorId: users[Math.floor(Math.random() * users.length)].id,
        });
        await this.commentRepository.save(comment);
      }

      // Add 5-15 random likes per post
      const numLikes = Math.floor(Math.random() * 11) + 5;
      const likedUsers = new Set<string>();

      for (let i = 0; i < numLikes && likedUsers.size < users.length; i++) {
        const user = users[Math.floor(Math.random() * users.length)];
        if (!likedUsers.has(user.id)) {
          likedUsers.add(user.id);
          const like = this.likeRepository.create({
            postId: post.id,
            userId: user.id,
          });
          await this.likeRepository.save(like);
        }
      }
    }

    // Create follow relationships
    for (let i = 0; i < users.length; i++) {
      for (let j = 0; j < users.length; j++) {
        if (i !== j && Math.random() > 0.4) { // 60% chance of following
          const follow = this.followRepository.create({
            followerId: users[i].id,
            followingId: users[j].id,
          });
          await this.followRepository.save(follow);
        }
      }
    }
  }

  private async createTestEventParticipants(users: User[], events: Event[]): Promise<void> {
    this.logger.log('Creating test event participants...');

    const statuses = [ParticipantStatus.ATTENDING, ParticipantStatus.INTERESTED, ParticipantStatus.NOT_ATTENDING];

    for (const event of events) {
      // Add participants for each event
      const participantCount = Math.floor(Math.random() * users.length) + 1;
      const participantUsers = users.slice(0, participantCount);

      for (const user of participantUsers) {
        const participant = this.eventParticipantRepository.create({
          eventId: event.id,
          userId: user.id,
          status: statuses[Math.floor(Math.random() * statuses.length)],
        });

        await this.eventParticipantRepository.save(participant);
      }
    }
  }

  private async createTestPetitionSignatures(users: User[], petitions: Petition[]): Promise<void> {
    this.logger.log('Creating test petition signatures...');

    const signatureComments = [
      'This is crucial for our community!',
      'Fully support this initiative.',
      'Our children deserve better.',
      'It\'s time for change.',
      'This will make a real difference.',
      null, // Some signatures without comments
    ];

    for (const petition of petitions) {
      // Add signatures for each petition (50-80% of users)
      const signatureCount = Math.floor(users.length * (0.5 + Math.random() * 0.3));
      const signingUsers = users.slice(0, signatureCount);

      for (const user of signingUsers) {
        const signature = this.petitionSignatureRepository.create({
          petitionId: petition.id,
          userId: user.id,
          comment: signatureComments[Math.floor(Math.random() * signatureComments.length)],
          isPublic: Math.random() > 0.1, // 90% public signatures
        });

        await this.petitionSignatureRepository.save(signature);
      }

      // Update petition signature count
      await this.petitionRepository.update(petition.id, {
        currentSignatures: signatureCount,
      });
    }
  }
}