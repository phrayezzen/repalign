import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { CongressApiService, CongressMember } from './congress-api.service';
import { LegislatorsService } from './legislators.service';
import { Repository } from 'typeorm';
import { Legislator } from './entities/legislator.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Party } from '../users/entities/legislator-profile.entity';

async function seedLegislators() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const congressApi = app.get(CongressApiService);
  const legislatorRepository = app.get<Repository<Legislator>>(
    getRepositoryToken(Legislator),
  );

  console.log('🏛️ Starting legislator import...');

  try {
    // Fetch all current members from Congress API
    const members = await congressApi.getCurrentMembers();

    if (members.length === 0) {
      console.warn('⚠️ No members found from API');
      return;
    }

    console.log(`📊 Found ${members.length} members to process`);

    // Process members in batches
    const batchSize = 10;
    let imported = 0;
    let updated = 0;
    let errors = 0;

    for (let i = 0; i < members.length; i += batchSize) {
      const batch = members.slice(i, i + batchSize);
      console.log(
        `📦 Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(members.length / batchSize)}`,
      );

      for (const member of batch) {
        try {
          const result = await processLegislator(
            member,
            legislatorRepository,
            congressApi,
          );
          if (result === 'imported') imported++;
          else if (result === 'updated') updated++;
        } catch (error) {
          console.error(
            `❌ Failed to process ${member.firstName} ${member.lastName} (${member.bioguideId})`,
            error.message,
          );
          errors++;
        }
      }

      // Small delay between batches
      await new Promise((resolve) => setTimeout(resolve, 100));
    }

    console.log(
      `✅ Import complete! Imported: ${imported}, Updated: ${updated}, Errors: ${errors}`,
    );
  } catch (error) {
    console.error('💥 Failed to import legislators', error);
    throw error;
  } finally {
    await app.close();
  }
}

async function processLegislator(
  member: CongressMember,
  repository: Repository<Legislator>,
  congressApi: CongressApiService,
): Promise<'imported' | 'updated'> {
  // Check if legislator already exists
  const existing = await repository.findOne({
    where: { bioguideId: member.bioguideId },
  });

  const legislatorData: Partial<Legislator> = {
    firstName: member.firstName,
    lastName: member.lastName,
    photoUrl: member.photoUrl,
    initials: generateInitials(member.firstName, member.lastName),
    chamber: member.chamber,
    state: member.state.toUpperCase(),
    district: member.district,
    party: member.party as Party,
    yearsInOffice: congressApi.calculateYearsInOffice(member.termStart),
    bioguideId: member.bioguideId,
  };

  if (existing) {
    // Update existing record
    await repository.update(existing.id, legislatorData);
    console.log(`🔄 Updated ${member.firstName} ${member.lastName}`);
    return 'updated';
  } else {
    // Create new record
    const legislator = repository.create(legislatorData);
    await repository.save(legislator);
    console.log(`✨ Imported ${member.firstName} ${member.lastName}`);
    return 'imported';
  }
}

function generateInitials(firstName: string, lastName: string): string {
  const first = firstName?.charAt(0)?.toUpperCase() || '';
  const last = lastName?.charAt(0)?.toUpperCase() || '';
  return `${first}${last}`;
}

// Run the script
seedLegislators()
  .then(() => {
    console.log('🎉 Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  });