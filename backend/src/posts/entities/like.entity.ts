import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  Index,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Post } from './post.entity';
import { Comment } from './comment.entity';

@Entity('likes')
@Index(['postId'])
@Index(['commentId'])
@Index(['userId'])
@Unique(['postId', 'userId']) // Ensure user can only like a post once
@Unique(['commentId', 'userId']) // Ensure user can only like a comment once
export class Like {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'post_id', nullable: true })
  postId: string;

  @Column({ name: 'comment_id', nullable: true })
  commentId: string;

  @Column({ name: 'user_id' })
  userId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => Post, (post) => post.likes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'post_id' })
  post: Post;

  @ManyToOne(() => Comment, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'comment_id' })
  comment: Comment;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;
}