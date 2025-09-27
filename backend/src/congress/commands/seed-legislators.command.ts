import { Command, CommandRunner } from 'nest-commander';
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Legislator } from '../entities/legislator.entity';
import { CongressApiService, CongressMember } from '../congress-api.service';
import { Party } from '../../users/entities/legislator-profile.entity';

@Injectable()
@Command({
  name: 'seed:legislators',
  description: 'Import all current legislators from Congress.gov API',
  options: { isDefault: false },
})
export class SeedLegislatorsCommand extends CommandRunner {
  private readonly logger = new Logger(SeedLegislatorsCommand.name);

  constructor(
    @InjectRepository(Legislator)
    private legislatorRepository: Repository<Legislator>,
    private congressApiService: CongressApiService,
  ) {
    super();
  }

  async run(): Promise<void> {
    this.logger.log('Starting legislator import...');

    try {
      // Fetch all current members from Congress API
      const members = await this.congressApiService.getCurrentMembers();

      if (members.length === 0) {
        this.logger.warn('No members found from API');
        return;
      }

      this.logger.log(`Found ${members.length} members to process`);

      // Process members in batches to avoid overwhelming the database
      const batchSize = 10;
      let imported = 0;
      let updated = 0;
      let errors = 0;

      for (let i = 0; i < members.length; i += batchSize) {
        const batch = members.slice(i, i + batchSize);
        this.logger.log(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(members.length / batchSize)}`);

        for (const member of batch) {
          try {
            const result = await this.processLegislator(member);
            if (result === 'imported') imported++;
            else if (result === 'updated') updated++;
          } catch (error) {
            this.logger.error(`Failed to process ${member.firstName} ${member.lastName} (${member.bioguideId})`, error.stack);
            errors++;
          }
        }

        // Small delay between batches to be respectful
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      this.logger.log(`Import complete! Imported: ${imported}, Updated: ${updated}, Errors: ${errors}`);
    } catch (error) {
      this.logger.error('Failed to import legislators', error.stack);
      throw error;
    }
  }

  private async processLegislator(member: CongressMember): Promise<'imported' | 'updated'> {
    // Check if legislator already exists
    const existing = await this.legislatorRepository.findOne({
      where: { bioguideId: member.bioguideId },
    });

    const legislatorData: Partial<Legislator> = {
      firstName: member.firstName,
      lastName: member.lastName,
      photoUrl: member.photoUrl,
      initials: this.generateInitials(member.firstName, member.lastName),
      chamber: member.chamber,
      state: member.state.toUpperCase(),
      district: member.district,
      party: member.party as any,
      yearsInOffice: this.congressApiService.calculateYearsInOffice(member.termStart),
      bioguideId: member.bioguideId,
    };

    if (existing) {
      // Update existing record
      await this.legislatorRepository.update(existing.id, legislatorData);
      this.logger.debug(`Updated ${member.firstName} ${member.lastName}`);
      return 'updated';
    } else {
      // Create new record
      const legislator = this.legislatorRepository.create(legislatorData);
      await this.legislatorRepository.save(legislator);
      this.logger.debug(`Imported ${member.firstName} ${member.lastName}`);
      return 'imported';
    }
  }

  private generateInitials(firstName: string, lastName: string): string {
    const first = firstName?.charAt(0)?.toUpperCase() || '';
    const last = lastName?.charAt(0)?.toUpperCase() || '';
    return `${first}${last}`;
  }
}