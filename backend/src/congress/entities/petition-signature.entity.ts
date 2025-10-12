import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Petition } from './petition.entity';

@Entity('petition_signatures')
@Index(['petitionId'])
@Index(['userId'])
@Index(['signedAt'])
@Unique(['petitionId', 'userId']) // Ensure user can only sign once
export class PetitionSignature {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'petition_id' })
  petitionId: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ type: 'text', nullable: true })
  comment: string;

  @Column({ name: 'is_public', default: true })
  isPublic: boolean;

  @CreateDateColumn({ name: 'signed_at' })
  signedAt: Date;

  // Relationships
  @ManyToOne(() => Petition, (petition) => petition.signatures, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'petition_id' })
  petition: Petition;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  // Helper methods
  get hasComment(): boolean {
    return !!this.comment && this.comment.trim().length > 0;
  }

  get displayName(): string {
    if (!this.isPublic) return 'Anonymous';
    return this.user?.displayName || 'Anonymous';
  }
}