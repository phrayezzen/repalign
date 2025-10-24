import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
  Unique,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Legislator } from './legislator.entity';

@Entity('legislator_follows')
@Index(['userId'])
@Index(['legislatorId'])
@Unique(['userId', 'legislatorId']) // Ensure user can only follow a legislator once
export class LegislatorFollow {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'legislator_id' })
  legislatorId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Legislator, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'legislator_id' })
  legislator: Legislator;
}
