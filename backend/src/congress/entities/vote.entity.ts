import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  Index,
  JoinColumn,
} from 'typeorm';
import { LegislatorProfile } from '../../users/entities/legislator-profile.entity';
import { Bill } from './bill.entity';

export enum VotePosition {
  YES = 'Yes',
  NO = 'No',
  ABSTAIN = 'Abstain',
  ABSENT = 'Absent',
}

@Entity('votes')
@Index(['legislatorId'])
@Index(['billId'])
@Index(['position'])
@Index(['timestamp'])
export class Vote {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'legislator_id' })
  legislatorId: string;

  @Column({ name: 'bill_id' })
  billId: string;

  @Column({
    type: 'enum',
    enum: VotePosition,
  })
  position: VotePosition;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  timestamp: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => LegislatorProfile, (legislator) => legislator.votes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'legislator_id' })
  legislator: LegislatorProfile;

  @ManyToOne(() => Bill, (bill) => bill.votes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bill_id' })
  bill: Bill;
}