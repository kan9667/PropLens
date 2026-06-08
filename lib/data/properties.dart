//mock database

//property model, better than using dynamic maps- provides type safety, better readability, compile time error checking 

// a list stores multiple values

import 'types.dart'; //using property class

final List<Property> mockProperties = [ //mock properties exists in RAM, when app closes data disapperars, a database store data permanently

  //property object created from class property(blueprint)
//property 1
  Property(
  id: '1',
  imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=80',
  bhk: 2,
  area: 1200,
  location: 'Sector 50, Gurgaon',
  sector: 50,
  price: 7500000,
  amenities: [
    'gym',
    'pool',
    'sunlight',
    'park',
  ],
  furnishing: 'furnished',
  ageYears: 2,
  floor: 5,
  totalFloors: 12,
  nearbySchools: [
    'DPS',
    'GD Goenka',
  ],
  nearbyHospitals: [
    'Medanta',
  ],
  parking: 1,
),

//property 2
Property(
  id: '2',
  imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
  
  bhk: 3,
  area: 1650,
  location: 'DLF Phase 1, Gurgaon',
  sector: 65,
  price: 12500000,
  amenities: [
    'gym',
    'pool',
    'metro',
  ],
  furnishing: 'semi-furnished',
  ageYears: 1,
  floor: 9,
  totalFloors: 18,
  nearbySchools: [
    'Pathways',
  ],
  nearbyHospitals: [
    'Artemis',
  ],
  parking: 2,
),

//property 3
Property(
  id: '3',
  imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&auto=format&fit=crop&q=80',
  bhk: 1,
  area: 650,
  location: 'Sohna Road, Gurgaon',
  sector: 52,
  price: 4500000,
  amenities: [
    'metro',
    'park',
  ],
  furnishing: 'unfurnished',
  ageYears: 4,
  floor: 2,
  totalFloors: 6,
  nearbySchools: [
    'DPS',
  ],
  nearbyHospitals: [
    'Fortis',
  ],
  parking: 1,
),

//property 4
Property(
  id: '4',
  imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&auto=format&fit=crop&q=80',
  bhk: 2,
  area: 1100,
  location: 'Sector 57, Gurgaon',
  sector: 57,
  price: 6800000,
  amenities: ['gym', 'park'],
  furnishing: 'semi-furnished',
  ageYears: 3,
  floor: 4,
  totalFloors: 10,
  nearbySchools: ['Shriram'],
  nearbyHospitals: ['Artemis'],
  parking: 1,
),

//property 5
Property(
  id: '5',
  imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&auto=format&fit=crop&q=80',
  bhk: 2,
  area: 1300,
  location: 'Sector 83, Gurgaon',
  sector: 83,
  price: 8200000,
  amenities: ['pool', 'sunlight'],
  furnishing: 'furnished',
  ageYears: 1,
  floor: 7,
  totalFloors: 14,
  nearbySchools: ['DPS'],
  nearbyHospitals: ['Medanta'],
  parking: 1,
),

//property 6
Property(
  id: '6',
  imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&auto=format&fit=crop&q=80',
  bhk: 3,
  area: 1800,
  location: 'Golf Course Road, Gurgaon',
  sector: 53,
  price: 14000000,
  amenities: ['gym', 'pool', 'sunlight'],
  furnishing: 'furnished',
  ageYears: 2,
  floor: 10,
  totalFloors: 20,
  nearbySchools: ['Pathways'],
  nearbyHospitals: ['Fortis'],
  parking: 2,
),

//property 7
Property(
  id: '7',
  imageUrl: 'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800&auto=format&fit=crop&q=80',
  bhk: 1,
  area: 700,
  location: 'Sector 65, Gurgaon',
  sector: 65,
  price: 5000000,
  amenities: ['metro'],
  furnishing: 'semi-furnished',
  ageYears: 5,
  floor: 3,
  totalFloors: 8,
  nearbySchools: ['GD Goenka'],
  nearbyHospitals: ['Artemis'],
  parking: 1,
),

//property 8
Property(
  id: '8',
  imageUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&auto=format&fit=crop&q=80',
  bhk: 2,
  area: 1250,
  location: 'Sector 50, Gurgaon',
  sector: 50,
  price: 7900000,
  amenities: ['gym', 'metro', 'park'],
  furnishing: 'furnished',
  ageYears: 2,
  floor: 6,
  totalFloors: 12,
  nearbySchools: ['DPS'],
  nearbyHospitals: ['Medanta'],
  parking: 1,
),

//property 9
Property(
  id: '9',
  imageUrl: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&auto=format&fit=crop&q=80',
  bhk: 3,
  area: 1700,
  location: 'Sector 52, Gurgaon',
  sector: 52,
  price: 13000000,
  amenities: ['pool', 'park'],
  furnishing: 'semi-furnished',
  ageYears: 4,
  floor: 8,
  totalFloors: 16,
  nearbySchools: ['Shriram'],
  nearbyHospitals: ['Fortis'],
  parking: 2,
),

//property 10
Property(
  id: '10',
  imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&auto=format&fit=crop&q=80',
  bhk: 2,
  area: 1150,
  location: 'Sector 57, Gurgaon',
  sector: 57,
  price: 7200000,
  amenities: ['sunlight', 'park'],
  furnishing: 'unfurnished',
  ageYears: 6,
  floor: 2,
  totalFloors: 9,
  nearbySchools: ['GD Goenka'],
  nearbyHospitals: ['Artemis'],
  parking: 1,
),

//property 11
Property(
  id: '11',
  imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&auto=format&fit=crop&q=80',
  bhk: 1,
  area: 600,
  location: 'Sector 83, Gurgaon',
  sector: 83,
  price: 4700000,
  amenities: ['metro', 'gym'],
  furnishing: 'semi-furnished',
  ageYears: 3,
  floor: 5,
  totalFloors: 11,
  nearbySchools: ['DPS'],
  nearbyHospitals: ['Medanta'],
  parking: 1,
),

//property 12
Property(
  id: '12',
  imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&auto=format&fit=crop&q=80',
  bhk: 2,
  area: 1350,
  location: 'Sector 53, Gurgaon',
  sector: 53,
  price: 8800000,
  amenities: ['gym', 'pool', 'metro'],
  furnishing: 'furnished',
  ageYears: 1,
  floor: 11,
  totalFloors: 18,
  nearbySchools: ['Pathways'],
  nearbyHospitals: ['Fortis'],
  parking: 2,
),


];