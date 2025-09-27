import axios from 'axios';
import { ConfigModule } from '@nestjs/config';

// Simple test script to debug the API
async function testCongressApi() {
  const apiKey = 'sPpMK7CUh5I47bsZYt6rNI5i9K8adkRAvxpjsreE';
  const baseUrl = 'https://api.congress.gov/v3';

  try {
    console.log('🔍 Testing Congress API...');

    const response = await axios.get(`${baseUrl}/member/congress/118`, {
      params: {
        currentMember: 'True',
        limit: 3,
        'api_key': apiKey
      },
      timeout: 10000
    });

    console.log('✅ API call successful!');
    console.log('Response status:', response.status);
    console.log('Data structure:', JSON.stringify(response.data, null, 2));

    if (response.data?.members) {
      console.log(`📊 Found ${response.data.members.length} members`);

      // Test parsing one member
      const firstMember = response.data.members[0];
      console.log('🧪 Testing parsing logic for first member:');
      console.log('Raw member:', JSON.stringify(firstMember, null, 2));

      // Parse name
      const nameParts = firstMember.name?.split(', ') || [];
      const lastName = nameParts[0] || '';
      const firstNames = nameParts[1]?.split(' ') || [''];
      const firstName = firstNames[0] || '';

      // Determine chamber
      const latestTerm = firstMember.terms?.item?.[firstMember.terms.item.length - 1];
      const chamber = latestTerm?.chamber === 'Senate' || firstMember.district === undefined ? 'senate' : 'house';

      console.log('Parsed data:');
      console.log('- firstName:', firstName);
      console.log('- lastName:', lastName);
      console.log('- party:', firstMember.partyName);
      console.log('- state:', firstMember.state);
      console.log('- district:', firstMember.district);
      console.log('- chamber:', chamber);
      console.log('- bioguideId:', firstMember.bioguideId);
      console.log('- photoUrl:', firstMember.depiction?.imageUrl);
    }

  } catch (error) {
    console.error('❌ API call failed:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

testCongressApi();