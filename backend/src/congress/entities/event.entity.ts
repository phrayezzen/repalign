import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

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

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

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
}