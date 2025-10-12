import { Test, TestingModule } from '@nestjs/testing';
import { FeedController } from './feed.controller';
import { FeedService } from './feed.service';
import { FeedQueryDto } from './dto/feed-query.dto';
import { FeedResponseDto } from './dto/feed-response.dto';
import { FeedItemType } from './dto/feed-item.dto';

describe('FeedController', () => {
  let controller: FeedController;
  let feedService: FeedService;

  const mockFeedResponse: FeedResponseDto = {
    items: [
      {
        id: 'post-1',
        type: FeedItemType.POST,
        content: 'Test post content',
        authorId: 'user-1',
        authorName: 'Test User',
        authorAvatar: null,
        createdAt: new Date('2023-10-01'),
        postType: 'text',
        tags: ['test'],
        attachmentUrls: [],
        likeCount: 5,
        commentCount: 2,
        shareCount: 1,
      },
      {
        id: 'event-1',
        type: FeedItemType.EVENT,
        title: 'Test Event',
        content: 'Test event description',
        authorId: 'user-1',
        authorName: 'Test User',
        authorAvatar: null,
        createdAt: new Date('2023-10-02'),
        eventDate: new Date('2023-11-01'),
        eventLocation: 'Test Location',
        eventType: 'Town Hall',
      },
    ],
    total: 2,
    page: 1,
    limit: 10,
    hasMore: false,
  };

  const mockFeedService = {
    getFeed: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FeedController],
      providers: [
        {
          provide: FeedService,
          useValue: mockFeedService,
        },
      ],
    }).compile();

    controller = module.get<FeedController>(FeedController);
    feedService = module.get<FeedService>(FeedService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('getFeed', () => {
    it('should return feed items with default pagination', async () => {
      const query: FeedQueryDto = { page: 1, limit: 10 };

      mockFeedService.getFeed.mockResolvedValue(mockFeedResponse);

      const result = await controller.getFeed(query);

      expect(feedService.getFeed).toHaveBeenCalledWith(query);
      expect(result).toEqual(mockFeedResponse);
      expect(result.items).toHaveLength(2);
      expect(result.total).toBe(2);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
      expect(result.hasMore).toBe(false);
    });

    it('should return feed items with search parameter', async () => {
      const query: FeedQueryDto = { page: 1, limit: 10, search: 'test' };

      mockFeedService.getFeed.mockResolvedValue(mockFeedResponse);

      const result = await controller.getFeed(query);

      expect(feedService.getFeed).toHaveBeenCalledWith(query);
      expect(result).toEqual(mockFeedResponse);
    });

    it('should return feed items with custom pagination', async () => {
      const query: FeedQueryDto = { page: 2, limit: 5 };
      const customResponse = { ...mockFeedResponse, page: 2, limit: 5 };

      mockFeedService.getFeed.mockResolvedValue(customResponse);

      const result = await controller.getFeed(query);

      expect(feedService.getFeed).toHaveBeenCalledWith(query);
      expect(result.page).toBe(2);
      expect(result.limit).toBe(5);
    });

    it('should handle feed service errors', async () => {
      const query: FeedQueryDto = { page: 1, limit: 10 };
      const error = new Error('Database connection failed');

      mockFeedService.getFeed.mockRejectedValue(error);

      await expect(controller.getFeed(query)).rejects.toThrow('Database connection failed');
      expect(feedService.getFeed).toHaveBeenCalledWith(query);
    });
  });
});