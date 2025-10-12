import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

export enum BadgeType {
  CIVIC_CONNECTOR = 'civic_connector',
  ACTIVIST = 'activist',
  FIRST_POST = 'first_post',
  SOCIAL_BUTTERFLY = 'social_butterfly',
  THOUGHT_LEADER = 'thought_leader',
}

@Entity('citizen_profiles')
export class CitizenProfile {
  @PrimaryColumn('uuid')
  userId: string;

  @Column({ name: 'civic_engagement_score', default: 0 })
  civicEngagementScore: number;

  @Column({ default: 1 })
  level: number;

  @Column({
    type: 'simple-array',
    default: '',
    transformer: {
      to: (value: BadgeType[]) => value?.join(',') || '',
      from: (value: string | BadgeType[]) => {
        if (Array.isArray(value)) return value;
        return value ? value.split(',').filter(Boolean) as BadgeType[] : [];
      },
    },
  })
  badges: BadgeType[];

  @Column({ name: 'is_civic_connector', default: false })
  isCivicConnector: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @OneToOne(() => User, (user) => user.citizenProfile)
  @JoinColumn({ name: 'user_id' })
  user: User;

  // Computed properties
  static calculateLevel(score: number): number {
    return Math.min(Math.max(1, Math.floor(score / 500) + 1), 10);
  }

  get nextLevelPoints(): number {
    const nextLevel = Math.min(this.level + 1, 10);
    return nextLevel * 500 - this.civicEngagementScore;
  }

  // Update level when score changes
  updateLevel(): void {
    this.level = CitizenProfile.calculateLevel(this.civicEngagementScore);
  }

  // Badge management
  addBadge(badge: BadgeType): void {
    if (!this.badges.includes(badge)) {
      this.badges.push(badge);
    }
  }

  hasBadge(badge: BadgeType): boolean {
    return this.badges.includes(badge);
  }
}