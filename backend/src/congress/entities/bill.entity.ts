import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { Vote } from './vote.entity';

export enum BillCategory {
  CLIMATE = 'Climate',
  HEALTHCARE = 'Healthcare',
  INFRASTRUCTURE = 'Infrastructure',
  EDUCATION = 'Education',
  ECONOMY = 'Economy',
  DEFENSE = 'Defense',
  SOCIAL_SERVICES = 'Social Services',
}

@Entity('bills')
@Index(['congressBillId'], { unique: true })
@Index(['category'])
@Index(['dateVoted'])
export class Bill {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'congress_bill_id', unique: true })
  congressBillId: string; // Official Congress bill ID (e.g., "H.R. 1234")

  @Column()
  title: string;

  @Column({ type: 'text', name: 'bill_description' })
  billDescription: string;

  @Column({
    type: 'enum',
    enum: BillCategory,
  })
  category: BillCategory;

  @Column({ type: 'decimal', precision: 15, scale: 2, nullable: true })
  amount: number;

  @Column({ name: 'date_voted', type: 'date' })
  dateVoted: Date;

  @Column({ name: 'is_aligned_with_user', default: true })
  isAlignedWithUser: boolean;

  @Column({ nullable: true })
  summary: string;

  @Column({ name: 'congress_url', nullable: true })
  congressUrl: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @OneToMany(() => Vote, (vote) => vote.bill)
  votes: Vote[];

  // Helper methods
  get formattedAmount(): string {
    if (!this.amount) return 'N/A';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(this.amount);
  }
}