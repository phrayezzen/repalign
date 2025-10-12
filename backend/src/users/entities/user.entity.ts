import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  OneToMany,
  Index,
} from 'typeorm';
import { Exclude } from 'class-transformer';
import { CitizenProfile } from './citizen-profile.entity';
import { LegislatorProfile } from './legislator-profile.entity';
import { Post } from '../../posts/entities/post.entity';
import { UserInterest } from './user-interest.entity';

export enum UserType {
  CITIZEN = 'citizen',
  LEGISLATOR = 'legislator',
  ORGANIZATION = 'organization',
}

@Entity('users')
@Index(['username'], { unique: true })
@Index(['email'], { unique: true })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  username: string;

  @Column({ unique: true })
  email: string;

  @Column({ name: 'phone_number', nullable: true, unique: true })
  phoneNumber: string;

  @Column({ name: 'display_name' })
  displayName: string;

  @Column({ type: 'text', nullable: true })
  bio: string;

  @Column({ name: 'profile_image_url', nullable: true })
  profileImageUrl: string;

  // Structured location fields
  @Column({ nullable: true })
  state: string;

  @Column({ name: 'congressional_district', nullable: true })
  congressionalDistrict: string;

  @Column({ nullable: true })
  city: string;

  // Legacy location field (computed or deprecated)
  @Column({ nullable: true })
  location: string;

  @Column({ name: 'posts_count', default: 0 })
  postsCount: number;

  @Column({ name: 'followers_count', default: 0 })
  followersCount: number;

  @Column({ name: 'following_count', default: 0 })
  followingCount: number;

  @Column({
    type: 'enum',
    enum: UserType,
    name: 'user_type',
  })
  userType: UserType;

  @Column({ name: 'is_verified', default: false })
  isVerified: boolean;

  @Column()
  @Exclude()
  password: string;

  @Column({ name: 'email_verified', default: false })
  emailVerified: boolean;

  @Column({ name: 'onboarding_completed', default: false })
  onboardingCompleted: boolean;

  @Column({ name: 'last_active', type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  lastActive: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @OneToOne(() => CitizenProfile, (profile) => profile.user, { cascade: true })
  citizenProfile?: CitizenProfile;

  @OneToOne(() => LegislatorProfile, (profile) => profile.user, { cascade: true })
  legislatorProfile?: LegislatorProfile;

  @OneToMany(() => Post, (post) => post.author)
  posts: Post[];

  @OneToMany(() => UserInterest, (interest) => interest.user)
  interests: UserInterest[];

  // Virtual properties (computed)
  get displayProfile(): CitizenProfile | LegislatorProfile | null {
    return this.userType === UserType.CITIZEN ? this.citizenProfile : this.legislatorProfile;
  }
}