import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';

export enum CauseType {
  CLIMATE_ENVIRONMENT = 'climate_environment',
  HOUSING_DEVELOPMENT = 'housing_development',
  VOTING_RIGHTS = 'voting_rights',
  HEALTHCARE = 'healthcare',
  EDUCATION = 'education',
  TRANSPORTATION = 'transportation',
  WORKERS_RIGHTS = 'workers_rights',
  CIVIL_RIGHTS = 'civil_rights',
  GOVERNMENT_REFORM = 'government_reform',
  COMMUNITY_SAFETY = 'community_safety',
  ECONOMIC_JUSTICE = 'economic_justice',
  IMMIGRATION = 'immigration',
}

@Entity('user_interests')
@Index(['userId', 'cause'], { unique: true }) // Prevent duplicate interests per user
export class UserInterest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({
    type: 'enum',
    enum: CauseType,
  })
  cause: CauseType;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;
}
