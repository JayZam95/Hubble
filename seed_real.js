const admin = require('firebase-admin');

// Initialize Firebase Admin (assuming default application credentials via system auth)
admin.initializeApp({
  projectId: 'hubble-intentgenesiscorp',
});

const db = admin.firestore();

const data = require('./test_data.json');
const batch = db.batch();

data.forEach(doc => {
  const ref = db.collection('users').doc(doc.id);
  batch.set(ref, doc);
});

batch.commit()
  .then(() => console.log('Successfully seeded test data.'))
  .catch(e => console.error('Error seeding test data:', e));
