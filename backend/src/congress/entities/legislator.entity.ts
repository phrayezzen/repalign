import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { Party } from '../../users/entities/legislator-profile.entity';

@Entity('legislators')
@Index(['bioguideId'], { unique: true })
@Index(['state'])
@Index(['chamber'])
@Index(['party'])
export class Legislator {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Basic Info (shown in header)
  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @Column({ nullable: true })
  photoUrl: string; // Profile photo URL

  @Column({ nullable: true })
  initials: string; // "SC" - for avatar fallback

  // Position Info
  @Column({
    type: 'enum',
    enum: ['house', 'senate'],
  })
  chamber: 'house' | 'senate';

  @Column({ length: 2 })
  state: string; // "CA"

  @Column({ nullable: true })
  district: string; // "11" (null for senators)

  @Column({
    type: 'enum',
    enum: Party,
  })
  party: Party;

  // Stats
  @Column({ default: 0 })
  yearsInOffice: number; // "6 years in office"

  @Column({ name: 'follower_count', default: 0 })
  followerCount: number;

  // Contact Information
  @Column({ name: 'phone_number', nullable: true })
  phoneNumber: string; // Office phone: "(202) 224-4543"

  @Column({ name: 'website_url', nullable: true })
  websiteUrl: string; // Official website

  @Column({ name: 'office_address', nullable: true })
  officeAddress: string; // "Washington, DC Office"

  // About/Bio
  @Column({ type: 'text', nullable: true })
  bio: string; // Biography/about text

  // External IDs for data import
  @Column({ unique: true })
  bioguideId: string; // Official Congressional Bioguide ID

  // Optional link to user account if claimed
  @Column({ nullable: true })
  userId: string; // Links to users table if legislator registers

  // Timestamps
  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Computed properties
  get title(): string {
    return this.chamber === 'senate' ? 'Sen.' : 'Rep.';
  }

  get position(): string {
    return this.chamber === 'senate' ? 'Senator' : 'House Representative';
  }

  get displayName(): string {
    return `${this.title} ${this.firstName} ${this.lastName}`;
  }

  get districtDisplay(): string {
    if (this.chamber === 'senate') return this.state;
    return `${this.state}-${this.district}`;
  }
}