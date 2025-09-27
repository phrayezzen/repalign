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

@Entity('posts')
@Index(['authorId'])
@Index(['createdAt'])
export class Post {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'author_id' })
  authorId: string;

  @Column({ type: 'text' })
  content: string;

  @Column({
    type: 'simple-array',
    default: '',
    transformer: {
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string) => value ? value.split(',').filter(Boolean) : [],
    },
  })
  tags: string[];

  @Column({
    name: 'attachment_urls',
    type: 'simple-array',
    default: '',
    transformer: {
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string) => value ? value.split(',').filter(Boolean) : [],
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

  // Computed properties
  get engagementCount(): number {
    return this.likeCount + this.commentCount + this.shareCount;
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
}