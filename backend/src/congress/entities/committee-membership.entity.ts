import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export enum CommitteeRole {
  CHAIR = 'Chair',
  RANKING_MEMBER = 'Ranking Member',
  MEMBER = 'Member',
}

@Entity('committee_memberships')
@Index(['legislatorId'])
export class CommitteeMembership {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'legislator_id' })
  legislatorId: string;

  @Column({ name: 'committee_name' })
  committeeName: string;

  @Column({
    type: 'enum',
    enum: CommitteeRole,
    default: CommitteeRole.MEMBER,
  })
  role: CommitteeRole;

  @Column({ name: 'start_date', type: 'date', nullable: true })
  startDate: Date;

  @Column({ name: 'end_date', type: 'date', nullable: true })
  endDate: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
