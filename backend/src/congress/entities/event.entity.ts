import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { EventParticipant } from './event-participant.entity';

export enum EventType {
  TOWN_HALL = 'Town Hall',
  DEBATE = 'Debate',
  COMMITTEE_HEARING = 'Committee Hearing',
  FUNDRAISER = 'Fundraiser',
  CAMPAIGN_EVENT = 'Campaign Event',
  COMMUNITY_MEETING = 'Community Meeting',
}

@Entity('events')
@Index(['date'])
@Index(['eventType'])
@Index(['location'])
@Index(['organizerId'])
@Index(['creatorUserId'])
export class Event {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text', name: 'event_description' })
  eventDescription: string;

  @Column({
    type: 'enum',
    enum: EventType,
    name: 'event_type',
  })
  eventType: EventType;

  @Column({ type: 'timestamp' })
  date: Date;

  @Column()
  location: string;

  @Column({ name: 'organizer_id', nullable: true })
  organizerId: string; // Could be a legislator or organization

  @Column({ name: 'creator_user_id' })
  creatorUserId: string; // User who created the event

  @Column({
    name: 'featured_legislator_ids',
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
  featuredLegislatorIds: string[];

  @Column({ name: 'max_attendees', nullable: true })
  maxAttendees: number;

  @Column({ name: 'current_attendees', default: 0 })
  currentAttendees: number;

  @Column({ name: 'registration_url', nullable: true })
  registrationUrl: string;

  @Column({ name: 'is_virtual', default: false })
  isVirtual: boolean;

  @Column({ name: 'virtual_link', nullable: true })
  virtualLink: string;

  @Column({ name: 'event_end_date', type: 'timestamp', nullable: true })
  eventEndDate: Date;

  @Column({ name: 'event_address', nullable: true })
  eventAddress: string;

  @Column({ name: 'event_duration', nullable: true })
  eventDuration: string;

  @Column({ name: 'event_format', nullable: true })
  eventFormat: string;

  @Column({ name: 'event_note', type: 'text', nullable: true })
  eventNote: string;

  @Column({ name: 'event_detailed_description', type: 'text', nullable: true })
  eventDetailedDescription: string;

  @Column({ name: 'hero_image_url', nullable: true })
  heroImageUrl: string;

  @Column({ name: 'organizer_followers', nullable: true })
  organizerFollowers: number;

  @Column({ name: 'organizer_events_count', nullable: true })
  organizerEventsCount: number;

  @Column({ name: 'organizer_years_active', nullable: true })
  organizerYearsActive: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'creator_user_id' })
  creator: User;

  @OneToMany(() => EventParticipant, (participant) => participant.event, { cascade: true })
  participants: EventParticipant[];

  // Helper methods
  get isUpcoming(): boolean {
    return this.date > new Date();
  }

  get isPast(): boolean {
    return this.date < new Date();
  }

  get spotsAvailable(): number {
    if (!this.maxAttendees) return Infinity;
    return Math.max(0, this.maxAttendees - this.currentAttendees);
  }

  get isFull(): boolean {
    if (!this.maxAttendees) return false;
    return this.currentAttendees >= this.maxAttendees;
  }

  get attendingCount(): number {
    return this.participants?.filter(p => p.isAttending).length || 0;
  }

  get interestedCount(): number {
    return this.participants?.filter(p => p.isInterested).length || 0;
  }

  get hasFeaturedLegislators(): boolean {
    return this.featuredLegislatorIds && this.featuredLegislatorIds.length > 0;
  }

  // Helper methods
  addFeaturedLegislator(legislatorId: string): void {
    if (!this.featuredLegislatorIds) this.featuredLegislatorIds = [];
    if (!this.featuredLegislatorIds.includes(legislatorId)) {
      this.featuredLegislatorIds.push(legislatorId);
    }
  }

  removeFeaturedLegislator(legislatorId: string): void {
    if (!this.featuredLegislatorIds) return;
    this.featuredLegislatorIds = this.featuredLegislatorIds.filter(id => id !== legislatorId);
  }

  updateAttendeeCount(): void {
    this.currentAttendees = this.attendingCount;
  }
}