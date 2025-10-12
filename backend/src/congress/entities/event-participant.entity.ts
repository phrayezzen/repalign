import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Event } from './event.entity';

export enum ParticipantStatus {
  INTERESTED = 'interested',
  ATTENDING = 'attending',
  NOT_ATTENDING = 'not_attending',
}

@Entity('event_participants')
@Index(['eventId'])
@Index(['userId'])
@Index(['status'])
@Index(['registeredAt'])
@Unique(['eventId', 'userId']) // Ensure user can only RSVP once per event
export class EventParticipant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'event_id' })
  eventId: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({
    type: 'enum',
    enum: ParticipantStatus,
    default: ParticipantStatus.INTERESTED,
  })
  status: ParticipantStatus;

  @CreateDateColumn({ name: 'registered_at' })
  registeredAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => Event, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'event_id' })
  event: Event;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  // Helper methods
  get isAttending(): boolean {
    return this.status === ParticipantStatus.ATTENDING;
  }

  get isInterested(): boolean {
    return this.status === ParticipantStatus.INTERESTED;
  }

  get isNotAttending(): boolean {
    return this.status === ParticipantStatus.NOT_ATTENDING;
  }

  setStatus(status: ParticipantStatus): void {
    this.status = status;
  }

  markAsAttending(): void {
    this.status = ParticipantStatus.ATTENDING;
  }

  markAsInterested(): void {
    this.status = ParticipantStatus.INTERESTED;
  }

  markAsNotAttending(): void {
    this.status = ParticipantStatus.NOT_ATTENDING;
  }
}