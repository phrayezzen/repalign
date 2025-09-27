import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

export enum ContributorType {
  INDIVIDUAL = 'Individual',
  CORPORATION = 'Corporation',
  PAC = 'PAC',
  SUPER_PAC = 'Super PAC',
  UNION = 'Union',
}

@Entity('campaign_contributors')
@Index(['legislatorId'])
@Index(['contributorType'])
@Index(['amount'])
@Index(['date'])
export class CampaignContributor {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'legislator_id' })
  legislatorId: string;

  @Column({ name: 'contributor_name' })
  contributorName: string;

  @Column({
    type: 'enum',
    enum: ContributorType,
    name: 'contributor_type',
  })
  contributorType: ContributorType;

  @Column({ type: 'decimal', precision: 15, scale: 2 })
  amount: number;

  @Column({ type: 'date' })
  date: Date;

  @Column({ nullable: true })
  industry: string;

  @Column({ name: 'election_cycle' })
  electionCycle: string; // e.g., "2024"

  @Column({ nullable: true })
  description: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Helper methods
  get formattedAmount(): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(this.amount);
  }

  get isLargeContribution(): boolean {
    return this.amount >= 10000; // $10k+ considered large
  }
}