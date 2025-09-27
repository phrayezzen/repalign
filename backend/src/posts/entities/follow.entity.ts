import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
  Unique,
} from 'typeorm';

@Entity('follows')
@Index(['followerId'])
@Index(['followingId'])
@Unique(['followerId', 'followingId']) // Ensure user can only follow someone once
export class Follow {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'follower_id' })
  followerId: string; // User who is following

  @Column({ name: 'following_id' })
  followingId: string; // User who is being followed

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}