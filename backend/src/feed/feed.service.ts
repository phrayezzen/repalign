import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Post } from '../posts/entities/post.entity';
import { Event } from '../congress/entities/event.entity';
import { Petition } from '../congress/entities/petition.entity';
import { User } from '../users/entities/user.entity';
import { FeedItemDto, FeedItemType } from './dto/feed-item.dto';
import { FeedResponseDto } from './dto/feed-response.dto';
import { FeedQueryDto } from './dto/feed-query.dto';

@Injectable()
export class FeedService {
  private readonly logger = new Logger(FeedService.name);

  constructor(
    @InjectRepository(Post)
    private postRepository: Repository<Post>,
    @InjectRepository(Event)
    private eventRepository: Repository<Event>,
    @InjectRepository(Petition)
    private petitionRepository: Repository<Petition>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async getFeed(query: FeedQueryDto): Promise<FeedResponseDto> {
    const { page, limit, search } = query;
    const offset = (page - 1) * limit;

    this.logger.log(`Getting feed: page=${page}, limit=${limit}, search=${search}`);

    try {
      // Get all content types with their authors
      this.logger.log('Fetching posts...');
      const posts = await this.getPosts(search);
      this.logger.log(`Got ${posts.length} posts`);

      this.logger.log('Fetching events...');
      const events = await this.getEvents(search);
      this.logger.log(`Got ${events.length} events`);

      this.logger.log('Fetching petitions...');
      const petitions = await this.getPetitions(search);
      this.logger.log(`Got ${petitions.length} petitions`);

      // Combine all items
      this.logger.log('Mapping posts...');
      const postItems = posts.map(post => {
        this.logger.log(`Mapping post: ${JSON.stringify({ id: post.id, tags: post.tags })}`);
        return this.mapPostToFeedItem(post);
      });

      this.logger.log('Mapping events...');
      const eventItems = events.map(event => this.mapEventToFeedItem(event));

      this.logger.log('Mapping petitions...');
      const petitionItems = petitions.map(petition => this.mapPetitionToFeedItem(petition));

      const allItems: FeedItemDto[] = [
        ...postItems,
        ...eventItems,
        ...petitionItems,
      ];

      // Sort by createdAt descending
      allItems.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

      // Apply pagination
      const total = allItems.length;
      const paginatedItems = allItems.slice(offset, offset + limit);
      const hasMore = offset + limit < total;

      return {
        items: paginatedItems,
        total,
        page,
        limit,
        hasMore,
      };
    } catch (error) {
      this.logger.error(`Error in getFeed: ${error.message}`, error.stack);
      throw error;
    }
  }

  private async getPosts(search?: string): Promise<Post[]> {
    const queryBuilder = this.postRepository
      .createQueryBuilder('post')
      .leftJoinAndSelect('post.author', 'author')
      .orderBy('post.createdAt', 'DESC');

    if (search) {
      queryBuilder.where('post.content ILIKE :search', { search: `%${search}%` });
    }

    return queryBuilder.getMany();
  }

  private async getEvents(search?: string): Promise<Event[]> {
    const queryBuilder = this.eventRepository
      .createQueryBuilder('event')
      .leftJoinAndSelect('event.creator', 'creator')
      .orderBy('event.createdAt', 'DESC');

    if (search) {
      queryBuilder.where(
        'event.title ILIKE :search OR event.eventDescription ILIKE :search',
        { search: `%${search}%` }
      );
    }

    return queryBuilder.getMany();
  }

  private async getPetitions(search?: string): Promise<Petition[]> {
    const queryBuilder = this.petitionRepository
      .createQueryBuilder('petition')
      .leftJoinAndSelect('petition.creator', 'creator')
      .orderBy('petition.createdAt', 'DESC');

    if (search) {
      queryBuilder.where(
        'petition.title ILIKE :search OR petition.description ILIKE :search',
        { search: `%${search}%` }
      );
    }

    return queryBuilder.getMany();
  }

  private mapPostToFeedItem(post: Post): FeedItemDto {
    return {
      id: post.id,
      type: FeedItemType.POST,
      content: post.content,
      authorId: post.authorId,
      authorName: post.author?.displayName || 'Unknown User',
      authorAvatar: post.author?.profileImageUrl,
      createdAt: post.createdAt,
      postType: post.postType,
      tags: post.tags || [],
      attachmentUrls: post.attachmentUrls || [],
      likeCount: post.likeCount || 0,
      commentCount: post.commentCount || 0,
      shareCount: post.shareCount || 0,
    };
  }

  private mapEventToFeedItem(event: Event): FeedItemDto {
    return {
      id: event.id,
      type: FeedItemType.EVENT,
      title: event.title,
      content: event.eventDescription,
      authorId: event.creatorUserId,
      authorName: event.creator?.displayName || 'Unknown User',
      authorAvatar: event.creator?.profileImageUrl,
      createdAt: event.createdAt,
      eventDate: event.date,
      eventLocation: event.location,
      eventType: event.eventType,
      eventEndDate: event.eventEndDate,
      eventAddress: event.eventAddress,
      eventDuration: event.eventDuration,
      eventFormat: event.eventFormat,
      eventNote: event.eventNote,
      eventDetailedDescription: event.eventDetailedDescription,
      heroImageUrl: event.heroImageUrl,
      organizerFollowers: event.organizerFollowers,
      organizerEventsCount: event.organizerEventsCount,
      organizerYearsActive: event.organizerYearsActive,
    };
  }

  private mapPetitionToFeedItem(petition: Petition): FeedItemDto {
    return {
      id: petition.id,
      type: FeedItemType.PETITION,
      title: petition.title,
      content: petition.description,
      authorId: petition.creatorId,
      authorName: petition.creator?.displayName || 'Unknown User',
      authorAvatar: petition.creator?.profileImageUrl,
      createdAt: petition.createdAt,
      petitionSignatures: petition.currentSignatures || 0,
      petitionTargetSignatures: petition.targetSignatures,
      petitionDeadline: petition.deadline,
      petitionCategory: petition.category,
    };
  }

}