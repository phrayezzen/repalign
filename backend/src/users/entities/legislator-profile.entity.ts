import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  JoinColumn,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';
import { Vote } from '../../congress/entities/vote.entity';

export enum PoliticalPosition {
  REPRESENTATIVE = 'Representative',
  SENATOR = 'Senator',
  GOVERNOR = 'Governor',
  MAYOR = 'Mayor',
}

export enum Party {
  DEMOCRAT = 'Democrat',
  REPUBLICAN = 'Republican',
  INDEPENDENT = 'Independent',
  GREEN = 'Green',
  LIBERTARIAN = 'Libertarian',
}

export enum MatchStatus {
  EXCELLENT_MATCH = 'Excellent Match',
  GOOD_MATCH = 'Good Match',
  FAIR_MATCH = 'Fair Match',
  POOR_MATCH = 'Poor Match',
}

@Entity('legislator_profiles')
@Index(['bioguideId'], { unique: true })
export class LegislatorProfile {
  @PrimaryColumn('uuid')
  userId: string;

  @Column({ name: 'bioguide_id', unique: true, nullable: true })
  bioguideId: string;

  @Column({
    type: 'enum',
    enum: PoliticalPosition,
  })
  position: PoliticalPosition;

  @Column({ nullable: true })
  district: string;

  @Column({
    type: 'enum',
    enum: Party,
  })
  party: Party;

  @Column({ name: 'years_in_office', default: 0 })
  yearsInOffice: number;

  @Column({ name: 'alignment_rating', type: 'decimal', precision: 5, scale: 2, default: 0 })
  alignmentRating: number;

  @Column({ name: 'responsiveness_rating', type: 'decimal', precision: 5, scale: 2, default: 0 })
  responsivenessRating: number;

  @Column({ name: 'transparency_rating', type: 'decimal', precision: 5, scale: 2, default: 0 })
  transparencyRating: number;

  @Column({ name: 'official_website_url', nullable: true })
  officialWebsiteUrl: string;

  @Column({ name: 'contact_phone_number', nullable: true })
  contactPhoneNumber: string;

  @Column({
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
  committees: string[];

  @Column({
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
  leadership: string[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relationships
  @OneToOne(() => User, (user) => user.legislatorProfile)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @OneToMany(() => Vote, (vote) => vote.legislator)
  votes: Vote[];

  // Computed properties
  get repAlignScore(): number {
    return (this.alignmentRating + this.responsivenessRating + this.transparencyRating) / 3.0;
  }

  get matchStatus(): MatchStatus {
    const score = this.repAlignScore;
    if (score >= 85) return MatchStatus.EXCELLENT_MATCH;
    if (score >= 70) return MatchStatus.GOOD_MATCH;
    if (score >= 50) return MatchStatus.FAIR_MATCH;
    return MatchStatus.POOR_MATCH;
  }

  get formattedPosition(): string {
    if (this.district) {
      return `${this.position} • ${this.district}`;
    }
    return this.position;
  }

  // Static helper methods
  static getMatchStatus(repAlignScore: number): MatchStatus {
    if (repAlignScore >= 85) return MatchStatus.EXCELLENT_MATCH;
    if (repAlignScore >= 70) return MatchStatus.GOOD_MATCH;
    if (repAlignScore >= 50) return MatchStatus.FAIR_MATCH;
    return MatchStatus.POOR_MATCH;
  }
}