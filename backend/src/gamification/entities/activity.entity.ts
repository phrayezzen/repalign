import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

export enum ActivityType {
  POST_CREATED = 'post_created',
  POST_LIKED = 'post_liked',
  COMMENT_POSTED = 'comment_posted',
  USER_FOLLOWED = 'user_followed',
  LEGISLATOR_CONTACTED = 'legislator_contacted',
  EVENT_ATTENDED = 'event_attended',
  BADGE_EARNED = 'badge_earned',
  LEVEL_UP = 'level_up',
  FIRST_LOGIN = 'first_login',
  PROFILE_COMPLETED = 'profile_completed',
}

@Entity('activities')
@Index(['userId'])
@Index(['activityType'])
@Index(['createdAt'])
export class Activity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({
    type: 'enum',
    enum: ActivityType,
    name: 'activity_type',
  })
  activityType: ActivityType;

  @Column({ name: 'points_awarded', default: 0 })
  pointsAwarded: number;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any>; // Flexible data for activity context

  @Column({ nullable: true })
  description: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Static point values for different activities
  static readonly POINT_VALUES: Record<ActivityType, number> = {
    [ActivityType.POST_CREATED]: 10,
    [ActivityType.POST_LIKED]: 2,
    [ActivityType.COMMENT_POSTED]: 5,
    [ActivityType.USER_FOLLOWED]: 3,
    [ActivityType.LEGISLATOR_CONTACTED]: 25,
    [ActivityType.EVENT_ATTENDED]: 50,
    [ActivityType.BADGE_EARNED]: 100,
    [ActivityType.LEVEL_UP]: 200,
    [ActivityType.FIRST_LOGIN]: 20,
    [ActivityType.PROFILE_COMPLETED]: 30,
  };

  static getPointsForActivity(activityType: ActivityType): number {
    return this.POINT_VALUES[activityType] || 0;
  }
}