import { Test, TestingModule } from '@nestjs/testing';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { FeedService } from './feed.service';
import { Post, PostType } from '../posts/entities/post.entity';
import { Event, EventType } from '../congress/entities/event.entity';
import { Petition, PetitionCategory, PetitionStatus } from '../congress/entities/petition.entity';
import { User, UserType } from '../users/entities/user.entity';
import { FeedItemType } from './dto/feed-item.dto';

describe('FeedService', () => {
  let service: FeedService;
  let postRepository: Repository<Post>;
  let eventRepository: Repository<Event>;
  let petitionRepository: Repository<Petition>;
  let userRepository: Repository<User>;

  const mockUser = {
    id: 'user-1',
    displayName: 'Test User',
    profileImageUrl: null,
    email: 'test@example.com',
    username: 'testuser',
    userType: UserType.CITIZEN,
  };

  const mockPost = {
    id: 'post-1',
    authorId: 'user-1',
    content: 'Test post content',
    postType: PostType.TEXT,
    tags: ['test', 'democracy'],
    attachmentUrls: [],
    likeCount: 5,
    commentCount: 2,
    shareCount: 1,
    createdAt: new Date('2023-10-01'),
    author: mockUser,
  };

  const mockEvent = {
    id: 'event-1',
    title: 'Test Event',
    eventDescription: 'Test event description',
    eventType: EventType.TOWN_HALL,
    date: new Date('2023-11-01'),
    location: 'Test Location',
    creatorUserId: 'user-1',
    featuredLegislatorIds: [],
    createdAt: new Date('2023-10-02'),
    creator: mockUser,
  };

  const mockPetition = {
    id: 'petition-1',
    title: 'Test Petition',
    description: 'Test petition description',
    targetSignatures: 1000,
    category: PetitionCategory.ENVIRONMENT,
    creatorId: 'user-1',
    recipientLegislatorIds: [],
    status: PetitionStatus.ACTIVE,
    deadline: new Date('2023-12-01'),
    createdAt: new Date('2023-10-03'),
    creator: mockUser,
    signatures: [],
  };

  const mockRepositoryFactory = () => ({
    createQueryBuilder: jest.fn(() => ({
      leftJoinAndSelect: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      getMany: jest.fn(),
    })),
    find: jest.fn(),
    findOne: jest.fn(),
    save: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FeedService,
        {
          provide: getRepositoryToken(Post),
          useFactory: mockRepositoryFactory,
        },
        {
          provide: getRepositoryToken(Event),
          useFactory: mockRepositoryFactory,
        },
        {
          provide: getRepositoryToken(Petition),
          useFactory: mockRepositoryFactory,
        },
        {
          provide: getRepositoryToken(User),
          useFactory: mockRepositoryFactory,
        },
      ],
    }).compile();

    service = module.get<FeedService>(FeedService);
    postRepository = module.get<Repository<Post>>(getRepositoryToken(Post));
    eventRepository = module.get<Repository<Event>>(getRepositoryToken(Event));
    petitionRepository = module.get<Repository<Petition>>(getRepositoryToken(Petition));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getFeed', () => {
    it('should return paginated feed items sorted by createdAt desc', async () => {
      // Mock the query builders
      const postQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockPost]),
      };

      const eventQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockEvent]),
      };

      const petitionQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockPetition]),
      };

      jest.spyOn(postRepository, 'createQueryBuilder').mockReturnValue(postQueryBuilder as any);
      jest.spyOn(eventRepository, 'createQueryBuilder').mockReturnValue(eventQueryBuilder as any);
      jest.spyOn(petitionRepository, 'createQueryBuilder').mockReturnValue(petitionQueryBuilder as any);

      const result = await service.getFeed({ page: 1, limit: 10 });

      expect(result.items).toHaveLength(3);
      expect(result.total).toBe(3);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
      expect(result.hasMore).toBe(false);

      // Check that items are sorted by createdAt desc (petition, event, post)
      expect(result.items[0].id).toBe('petition-1');
      expect(result.items[0].type).toBe(FeedItemType.PETITION);
      expect(result.items[1].id).toBe('event-1');
      expect(result.items[1].type).toBe(FeedItemType.EVENT);
      expect(result.items[2].id).toBe('post-1');
      expect(result.items[2].type).toBe(FeedItemType.POST);
    });

    it('should handle pagination correctly', async () => {
      const mockPosts = Array.from({ length: 15 }, (_, i) => ({
        ...mockPost,
        id: `post-${i}`,
        createdAt: new Date(`2023-10-${String(i + 1).padStart(2, '0')}`),
      }));

      const postQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(mockPosts),
      };

      const eventQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      };

      const petitionQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      };

      jest.spyOn(postRepository, 'createQueryBuilder').mockReturnValue(postQueryBuilder as any);
      jest.spyOn(eventRepository, 'createQueryBuilder').mockReturnValue(eventQueryBuilder as any);
      jest.spyOn(petitionRepository, 'createQueryBuilder').mockReturnValue(petitionQueryBuilder as any);

      const result = await service.getFeed({ page: 2, limit: 10 });

      expect(result.items).toHaveLength(5); // Remaining 5 items from total 15
      expect(result.total).toBe(15);
      expect(result.page).toBe(2);
      expect(result.limit).toBe(10);
      expect(result.hasMore).toBe(false);
    });

    it('should filter by search term', async () => {
      const postQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockPost]),
      };

      const eventQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      };

      const petitionQueryBuilder = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      };

      jest.spyOn(postRepository, 'createQueryBuilder').mockReturnValue(postQueryBuilder as any);
      jest.spyOn(eventRepository, 'createQueryBuilder').mockReturnValue(eventQueryBuilder as any);
      jest.spyOn(petitionRepository, 'createQueryBuilder').mockReturnValue(petitionQueryBuilder as any);

      await service.getFeed({ page: 1, limit: 10, search: 'test' });

      // Verify search filters were applied
      expect(postQueryBuilder.where).toHaveBeenCalledWith(
        'post.content ILIKE :search',
        { search: '%test%' }
      );
    });
  });
});