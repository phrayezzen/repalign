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
import { PetitionSignature } from './petition-signature.entity';

export enum PetitionCategory {
  HEALTHCARE = 'Healthcare',
  EDUCATION = 'Education',
  ENVIRONMENT = 'Environment',
  ECONOMY = 'Economy',
  JUSTICE = 'Justice',
  INFRASTRUCTURE = 'Infrastructure',
  CIVIL_RIGHTS = 'Civil Rights',
  DEFENSE = 'Defense',
  OTHER = 'Other',
}

export enum PetitionStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  CLOSED = 'closed',
  SUCCESSFUL = 'successful',
}

@Entity('petitions')
@Index(['creatorId'])
@Index(['status'])
@Index(['category'])
@Index(['deadline'])
export class Petition {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ name: 'target_signatures' })
  targetSignatures: number;

  @Column({
    type: 'enum',
    enum: PetitionCategory,
  })
  category: PetitionCategory;

  @Column({ name: 'creator_id' })
  creatorId: string;

  @Column({
    name: 'recipient_legislator_ids',
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
  recipientLegislatorIds: string[];

  @Column({
    type: 'enum',
    enum: PetitionStatus,
    default: PetitionStatus.DRAFT,
  })
  status: PetitionStatus;

  @Column({ type: 'timestamp', nullable: true })
  deadline: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'creator_id' })
  creator: User;

  @OneToMany(() => PetitionSignature, (signature) => signature.petition, { cascade: true })
  signatures: PetitionSignature[];

  // Computed properties
  get currentSignatures(): number {
    return this.signatures?.length || 0;
  }

  get progressPercentage(): number {
    if (this.targetSignatures === 0) return 0;
    return Math.min(100, (this.currentSignatures / this.targetSignatures) * 100);
  }

  get isActive(): boolean {
    return this.status === PetitionStatus.ACTIVE;
  }

  get isExpired(): boolean {
    if (!this.deadline) return false;
    return new Date() > this.deadline;
  }

  get isSuccessful(): boolean {
    return this.status === PetitionStatus.SUCCESSFUL ||
           this.currentSignatures >= this.targetSignatures;
  }

  get daysRemaining(): number {
    if (!this.deadline) return Infinity;
    const diffTime = this.deadline.getTime() - new Date().getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  // Helper methods
  canBeSigned(): boolean {
    return this.isActive && !this.isExpired;
  }

  markAsSuccessful(): void {
    if (this.isSuccessful) {
      this.status = PetitionStatus.SUCCESSFUL;
    }
  }

  close(): void {
    this.status = PetitionStatus.CLOSED;
  }
}