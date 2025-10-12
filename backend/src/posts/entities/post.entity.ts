import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Comment } from './comment.entity';
import { Like } from './like.entity';
import { Media } from './media.entity';
import { Event } from '../../congress/entities/event.entity';
import { Petition } from '../../congress/entities/petition.entity';

export enum PostType {
  TEXT = 'text',
  IMAGE = 'image',
  SHARED_EVENT = 'shared_event',
  SHARED_PETITION = 'shared_petition',
}

@Entity('posts')
@Index(['authorId'])
@Index(['createdAt'])
@Index(['postType'])
@Index(['sharedEventId'])
@Index(['sharedPetitionId'])
export class Post {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'author_id' })
  authorId: string;

  @Column({ type: 'text' })
  content: string;

  @Column({
    type: 'enum',
    enum: PostType,
    name: 'post_type',
    default: PostType.TEXT,
  })
  postType: PostType;

  @Column({ name: 'shared_event_id', nullable: true })
  sharedEventId: string;

  @Column({ name: 'shared_petition_id', nullable: true })
  sharedPetitionId: string;

  @Column({
    type: 'simple-array',
    default: '',
    transformer: {
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string | string[]) => {
        if (Array.isArray(value)) return value;
        return value ? value.split(',').filter(Boolean) : [];
      },
    },
  })
  tags: string[];

  @Column({
    name: 'attachment_urls',
    type: 'simple-array',
    default: '',
    transformer: {
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string | string[]) => {
        if (Array.isArray(value)) return value;
        return value ? value.split(',').filter(Boolean) : [];
      },
    },
  })
  attachmentUrls: string[];

  @Column({ name: 'like_count', default: 0 })
  likeCount: number;

  @Column({ name: 'comment_count', default: 0 })
  commentCount: number;

  @Column({ name: 'share_count', default: 0 })
  shareCount: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => User, (user) => user.posts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author: User;

  @OneToMany(() => Comment, (comment) => comment.post, { cascade: true })
  comments: Comment[];

  @OneToMany(() => Like, (like) => like.post, { cascade: true })
  likes: Like[];

  @OneToMany(() => Media, (media) => media.associatedPost, { cascade: true })
  media: Media[];

  @ManyToOne(() => Event, { nullable: true })
  @JoinColumn({ name: 'shared_event_id' })
  sharedEvent: Event;

  @ManyToOne(() => Petition, { nullable: true })
  @JoinColumn({ name: 'shared_petition_id' })
  sharedPetition: Petition;

  // Computed properties
  get engagementCount(): number {
    return this.likeCount + this.commentCount + this.shareCount;
  }

  get isTextPost(): boolean {
    return this.postType === PostType.TEXT;
  }

  get isImagePost(): boolean {
    return this.postType === PostType.IMAGE;
  }

  get isSharedEvent(): boolean {
    return this.postType === PostType.SHARED_EVENT;
  }

  get isSharedPetition(): boolean {
    return this.postType === PostType.SHARED_PETITION;
  }

  get hasMedia(): boolean {
    return this.media && this.media.length > 0;
  }

  get hasSharedContent(): boolean {
    return !!this.sharedEventId || !!this.sharedPetitionId;
  }

  // Helper methods
  incrementLikeCount(): void {
    this.likeCount += 1;
  }

  decrementLikeCount(): void {
    this.likeCount = Math.max(0, this.likeCount - 1);
  }

  incrementCommentCount(): void {
    this.commentCount += 1;
  }

  decrementCommentCount(): void {
    this.commentCount = Math.max(0, this.commentCount - 1);
  }

  incrementShareCount(): void {
    this.shareCount += 1;
  }

  shareEvent(eventId: string): void {
    this.postType = PostType.SHARED_EVENT;
    this.sharedEventId = eventId;
    this.sharedPetitionId = null;
  }

  sharePetition(petitionId: string): void {
    this.postType = PostType.SHARED_PETITION;
    this.sharedPetitionId = petitionId;
    this.sharedEventId = null;
  }

  addMedia(mediaItem: Media): void {
    if (!this.media) this.media = [];
    this.media.push(mediaItem);
    if (this.postType === PostType.TEXT) {
      this.postType = PostType.IMAGE;
    }
  }
}