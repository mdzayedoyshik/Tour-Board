// Security Rules tests. Run with `npm test` from rules_test/ (starts the
// Firestore emulator via `firebase emulators:exec`).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const PROJECT = 'demo-tour-board';
const T = 'tour1';
const CODE = 'K7QM4XPT9C2B';
const DAY = 24 * 60 * 60 * 1000;

let env;

const ts = (offsetMs = 0) => Timestamp.fromMillis(Date.now() + offsetMs);
const db = (uid) =>
  uid
    ? env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore()
    : env.unauthenticatedContext().firestore();

const settings = {
  adminsCanManageTour: true,
  membersCanEditPacking: true,
  membersCanRecordForOthers: false,
};

function tourDoc(overrides = {}) {
  return {
    name: 'Cox’s Bazar',
    hostUid: 'host',
    status: 'active',
    startAt: ts(),
    endAt: ts(3 * DAY),
    timeZone: 'Asia/Dhaka',
    currencyCode: 'BDT',
    inviteCode: CODE,
    allMemberUids: ['host', 'admin', 'alice', 'bob', 'gone'],
    settings,
    createdAt: ts(-DAY),
    updatedAt: ts(-DAY),
    schemaVersion: 1,
    ...overrides,
  };
}

function memberDoc(uid, role, status = 'active') {
  return {
    uid,
    displayNameSnapshot: uid,
    role,
    status,
    joinedAt: ts(-DAY),
    updatedAt: ts(-DAY),
  };
}

function expenseDoc(overrides = {}) {
  return {
    title: 'Dinner',
    amountMinor: 300,
    currencyCode: 'BDT',
    payerUid: 'alice',
    shares: { alice: 100, bob: 100, host: 100 },
    splitMethod: 'equal',
    category: 'food',
    occurredAt: ts(),
    createdBy: 'alice',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    revisionCount: 0,
    schemaVersion: 1,
    ...overrides,
  };
}

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

/** A tour with host, admin, alice, bob active and "gone" removed. */
async function seedTour(tourOverrides = {}) {
  await seed(async (f) => {
    await setDoc(doc(f, `tours/${T}`), tourDoc(tourOverrides));
    await setDoc(doc(f, `tours/${T}/members/host`), memberDoc('host', 'host'));
    await setDoc(doc(f, `tours/${T}/members/admin`), memberDoc('admin', 'admin'));
    await setDoc(doc(f, `tours/${T}/members/alice`), memberDoc('alice', 'member'));
    await setDoc(doc(f, `tours/${T}/members/bob`), memberDoc('bob', 'member'));
    await setDoc(
      doc(f, `tours/${T}/members/gone`),
      memberDoc('gone', 'member', 'removed'),
    );
    await setDoc(doc(f, `invites/${CODE}`), {
      tourId: T,
      tourName: 'Cox’s Bazar',
      hostUid: 'host',
      hostName: 'host',
      startAt: ts(),
      endAt: ts(3 * DAY),
      expiresAt: ts(7 * DAY),
      revoked: false,
      createdBy: 'host',
      createdAt: ts(-DAY),
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

// ---------------------------------------------------------------------------

describe('profiles', () => {
  const profile = (uid, overrides = {}) => ({
    uid,
    displayName: 'Alice',
    email: `${uid}@example.com`,
    locale: 'en',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('user can create and read only their own profile', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), profile('alice')));
    await assertFails(setDoc(doc(db('alice'), 'users/bob'), profile('bob')));
    await assertFails(getDoc(doc(db('bob'), 'users/alice')));
    await assertFails(getDoc(doc(db(null), 'users/alice')));
  });

  test('email must match the auth token and uid is immutable', async () => {
    await assertFails(
      setDoc(doc(db('alice'), 'users/alice'), profile('alice', { email: 'x@y.z' })),
    );
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), profile('alice')));
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { uid: 'bob', updatedAt: serverTimestamp() }));
    await assertFails(
      updateDoc(doc(db('alice'), 'users/alice'), { email: 'evil@x.y', updatedAt: serverTimestamp() }),
    );
    await assertSucceeds(
      updateDoc(doc(db('alice'), 'users/alice'), { displayName: 'Al', updatedAt: serverTimestamp() }),
    );
  });
});

describe('tour creation', () => {
  test('creator becomes host in one batch', async () => {
    const f = db('host');
    const b = writeBatch(f);
    b.set(doc(f, 'tours/new'), {
      ...tourDoc({ allMemberUids: ['host'], inviteCode: 'ABCDEFGHJKMN' }),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    b.set(doc(f, 'tours/new/members/host'), {
      ...memberDoc('host', 'host'),
      joinedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    b.set(doc(f, 'users/host/tourMemberships/new'), {
      tourId: 'new',
      joinedAt: serverTimestamp(),
    });
    b.set(doc(f, 'invites/ABCDEFGHJKMN'), {
      tourId: 'new',
      tourName: 'Trip',
      hostUid: 'host',
      hostName: 'host',
      startAt: ts(),
      endAt: ts(DAY),
      expiresAt: ts(14 * DAY),
      revoked: false,
      createdBy: 'host',
      createdAt: serverTimestamp(),
    });
    await assertSucceeds(b.commit());
  });

  test('cannot create a tour for someone else or without a host record', async () => {
    const f = db('alice');
    await assertFails(
      setDoc(doc(f, 'tours/x'), {
        ...tourDoc({ hostUid: 'bob', allMemberUids: ['bob'], inviteCode: null }),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(f, 'tours/x'), {
        ...tourDoc({ hostUid: 'alice', allMemberUids: ['alice'], inviteCode: null }),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('read access', () => {
  beforeEach(() => seedTour());

  test('unauthenticated users and non-members cannot read private data', async () => {
    for (const path of [
      `tours/${T}`,
      `tours/${T}/members/alice`,
      `tours/${T}/expenses/e1`,
      `tours/${T}/settlements/s1`,
      `tours/${T}/notes/n1`,
    ]) {
      await assertFails(getDoc(doc(db(null), path)));
      await assertFails(getDoc(doc(db('stranger'), path)));
    }
    await assertFails(getDocs(collection(db('stranger'), `tours/${T}/expenses`)));
  });

  test('members can read tour content', async () => {
    await assertSucceeds(getDoc(doc(db('alice'), `tours/${T}`)));
    await assertSucceeds(getDocs(collection(db('alice'), `tours/${T}/expenses`)));
    await assertSucceeds(getDocs(collection(db('alice'), `tours/${T}/members`)));
  });

  test('removed members lose access but can see their own record', async () => {
    await assertFails(getDoc(doc(db('gone'), `tours/${T}`)));
    await assertFails(getDocs(collection(db('gone'), `tours/${T}/expenses`)));
    await assertSucceeds(getDoc(doc(db('gone'), `tours/${T}/members/gone`)));
  });

  test('invites can be fetched by code but never listed', async () => {
    await assertSucceeds(getDoc(doc(db('stranger'), `invites/${CODE}`)));
    await assertFails(getDocs(collection(db('stranger'), 'invites')));
    await assertFails(getDoc(doc(db(null), `invites/${CODE}`)));
  });
});

describe('join requests and membership', () => {
  beforeEach(() => seedTour());

  const request = (uid, overrides = {}) => ({
    uid,
    displayNameSnapshot: uid,
    status: 'pending',
    attemptCount: 1,
    inviteCode: CODE,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('a user can request to join with a valid invite', async () => {
    await assertSucceeds(
      setDoc(doc(db('carol'), `tours/${T}/joinRequests/carol`), request('carol')),
    );
  });

  test('cannot request for someone else or with a bad invite', async () => {
    await assertFails(
      setDoc(doc(db('carol'), `tours/${T}/joinRequests/dave`), request('dave')),
    );
    await assertFails(
      setDoc(
        doc(db('carol'), `tours/${T}/joinRequests/carol`),
        request('carol', { inviteCode: 'ZZZZZZZZZZZZ' }),
      ),
    );
  });

  test('expired, revoked or rotated invites cannot be used', async () => {
    await seed((f) => updateDoc(doc(f, `invites/${CODE}`), { expiresAt: ts(-1000) }));
    await assertFails(
      setDoc(doc(db('carol'), `tours/${T}/joinRequests/carol`), request('carol')),
    );
    await seed((f) =>
      updateDoc(doc(f, `invites/${CODE}`), { expiresAt: ts(DAY), revoked: true }),
    );
    await assertFails(
      setDoc(doc(db('carol'), `tours/${T}/joinRequests/carol`), request('carol')),
    );
    await seed(async (f) => {
      await updateDoc(doc(f, `invites/${CODE}`), { revoked: false });
      await updateDoc(doc(f, `tours/${T}`), { inviteCode: 'NEWCODE00000' });
    });
    await assertFails(
      setDoc(doc(db('carol'), `tours/${T}/joinRequests/carol`), request('carol')),
    );
  });

  test('requester cannot self-approve or create their own membership', async () => {
    await seed((f) =>
      setDoc(doc(f, `tours/${T}/joinRequests/carol`), {
        ...request('carol'),
        createdAt: ts(),
        updatedAt: ts(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('carol'), `tours/${T}/joinRequests/carol`), {
        status: 'approved',
        reviewedBy: 'carol',
        reviewedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(db('carol'), `tours/${T}/members/carol`), {
        ...memberDoc('carol', 'member'),
        joinedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('carol'), `tours/${T}/joinRequests/carol`), {
        status: 'cancelled',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('host approves atomically; members cannot approve', async () => {
    await seed((f) =>
      setDoc(doc(f, `tours/${T}/joinRequests/carol`), {
        ...request('carol'),
        createdAt: ts(),
        updatedAt: ts(),
      }),
    );
    const approve = (uid) => {
      const f = db(uid);
      const b = writeBatch(f);
      b.update(doc(f, `tours/${T}/joinRequests/carol`), {
        status: 'approved',
        reviewedBy: uid,
        reviewedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      b.set(doc(f, `tours/${T}/members/carol`), {
        ...memberDoc('carol', 'member'),
        joinedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      b.update(doc(f, `tours/${T}`), {
        allMemberUids: ['host', 'admin', 'alice', 'bob', 'gone', 'carol'],
        updatedAt: serverTimestamp(),
      });
      b.set(doc(f, 'users/carol/tourMemberships/' + T), {
        tourId: T,
        joinedAt: serverTimestamp(),
      });
      return b.commit();
    };
    await assertFails(approve('alice'));
    await assertSucceeds(approve('host'));
    await assertSucceeds(getDoc(doc(db('carol'), `tours/${T}`)));
  });

  test('members cannot escalate roles; host can', async () => {
    await assertFails(
      updateDoc(doc(db('alice'), `tours/${T}/members/alice`), {
        role: 'admin',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('admin'), `tours/${T}/members/alice`), {
        role: 'admin',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('host'), `tours/${T}/members/alice`), {
        role: 'admin',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('alice'), `tours/${T}`), {
        hostUid: 'alice',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('admin removes members but not the host; host cannot leave', async () => {
    const remove = (by, uid) =>
      updateDoc(doc(db(by), `tours/${T}/members/${uid}`), {
        status: 'removed',
        removedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    await assertFails(remove('alice', 'bob'));
    await assertFails(remove('admin', 'host'));
    await assertSucceeds(remove('admin', 'bob'));
    await assertFails(getDoc(doc(db('bob'), `tours/${T}`)));
    await assertFails(
      updateDoc(doc(db('host'), `tours/${T}/members/host`), {
        status: 'left',
        removedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('host transfer requires both member updates in one batch', async () => {
    const f = db('host');
    const b = writeBatch(f);
    b.update(doc(f, `tours/${T}`), { hostUid: 'alice', updatedAt: serverTimestamp() });
    b.update(doc(f, `tours/${T}/members/alice`), { role: 'host', updatedAt: serverTimestamp() });
    b.update(doc(f, `tours/${T}/members/host`), { role: 'admin', updatedAt: serverTimestamp() });
    await assertSucceeds(b.commit());
    await assertFails(
      updateDoc(doc(db('admin'), `tours/${T}`), {
        hostUid: 'admin',
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('expenses', () => {
  beforeEach(() => seedTour());

  const add = (uid, data, id = 'e1') =>
    setDoc(doc(db(uid), `tours/${T}/expenses/${id}`), data);

  test('member adds own expense with a valid split', async () => {
    await assertSucceeds(add('alice', expenseDoc()));
  });

  test('payer is not included as participant', async () => {
    await assertSucceeds(add('alice', expenseDoc({ shares: { bob: 150, host: 150 } })));
  });

  test('invalid amounts, unknown fields and malformed splits are rejected', async () => {
    await assertFails(add('alice', expenseDoc({ amountMinor: -300 })));
    await assertFails(add('alice', expenseDoc({ amountMinor: 0, shares: { alice: 0 } })));
    await assertFails(add('alice', expenseDoc({ amountMinor: 1.5 })));
    await assertFails(add('alice', expenseDoc({ hacked: true })));
    await assertFails(add('alice', expenseDoc({ currencyCode: 'XXX' })));
    await assertFails(add('alice', expenseDoc({ shares: { alice: 100, bob: 100, host: 99 } })));
    await assertFails(add('alice', expenseDoc({ shares: { alice: 400, bob: -100 } })));
    await assertFails(add('alice', expenseDoc({ shares: { alice: 150, stranger: 150 } })));
    await assertFails(add('alice', expenseDoc({ shares: {} })));
    await assertFails(add('alice', expenseDoc({ shares: { alice: '300' } })));
    await assertFails(add('alice', expenseDoc({ payerUid: 'stranger' })));
  });

  test('more than 30 participants is rejected', async () => {
    await seed((f) =>
      updateDoc(doc(f, `tours/${T}`), {
        allMemberUids: Array.from({ length: 31 }, (_, i) => `u${i}`).concat(['alice']),
      }),
    );
    const shares = Object.fromEntries(Array.from({ length: 31 }, (_, i) => [`u${i}`, 10]));
    await assertFails(add('alice', expenseDoc({ amountMinor: 310, shares })));
    const ok = Object.fromEntries(Array.from({ length: 30 }, (_, i) => [`u${i}`, 10]));
    await assertSucceeds(add('alice', expenseDoc({ amountMinor: 300, shares: ok })));
  });

  test('historical (removed) members may appear in shares', async () => {
    await assertSucceeds(add('alice', expenseDoc({ shares: { alice: 150, gone: 150 } })));
  });

  test('members cannot forge createdBy or record for others', async () => {
    await assertFails(add('alice', expenseDoc({ createdBy: 'bob' })));
    await assertFails(add('alice', expenseDoc({ payerUid: 'bob' })));
    await assertSucceeds(add('admin', expenseDoc({ payerUid: 'bob', createdBy: 'admin' })));
    await assertFails(add('stranger', expenseDoc({ createdBy: 'stranger', payerUid: 'stranger' })));
  });

  describe('edits', () => {
    beforeEach(() =>
      seed((f) =>
        setDoc(doc(f, `tours/${T}/expenses/e1`), {
          ...expenseDoc(),
          createdAt: ts(-1000),
          updatedAt: ts(-1000),
        }),
      ),
    );

    const edit = (uid, changes, withRevision = true) => {
      const f = db(uid);
      const b = writeBatch(f);
      b.update(doc(f, `tours/${T}/expenses/e1`), {
        ...changes,
        revisionCount: 1,
        updatedBy: uid,
        updatedAt: serverTimestamp(),
      });
      if (withRevision) {
        b.set(doc(f, `tours/${T}/expenses/e1/revisions/1`), {
          editorUid: uid,
          editedAt: serverTimestamp(),
          changedFields: Object.keys(changes),
          before: {},
          after: {},
        });
      }
      return b.commit();
    };

    test('owner edits with a revision; edits without revision fail', async () => {
      await assertFails(edit('alice', { title: 'Lunch' }, false));
      await assertSucceeds(edit('alice', { title: 'Lunch' }));
    });

    test("member cannot modify another member's expense; admin can", async () => {
      await assertFails(edit('bob', { title: 'Mine now' }));
      await assertSucceeds(edit('admin', { title: 'Fixed' }));
    });

    test('revisions are immutable and cannot be forged standalone', async () => {
      await assertFails(
        setDoc(doc(db('alice'), `tours/${T}/expenses/e1/revisions/1`), {
          editorUid: 'alice',
          editedAt: serverTimestamp(),
          changedFields: ['title'],
          before: {},
          after: {},
        }),
      );
      await assertSucceeds(edit('alice', { title: 'Lunch' }));
      await assertFails(
        updateDoc(doc(db('alice'), `tours/${T}/expenses/e1/revisions/1`), { reason: 'x' }),
      );
    });

    test('soft delete is terminal and cannot be resurrected', async () => {
      await assertSucceeds(
        edit('alice', { deletedAt: serverTimestamp(), deletedBy: 'alice' }),
      );
      const f = db('admin');
      const b = writeBatch(f);
      b.update(doc(f, `tours/${T}/expenses/e1`), {
        deletedAt: null,
        deletedBy: null,
        revisionCount: 2,
        updatedBy: 'admin',
        updatedAt: serverTimestamp(),
      });
      b.set(doc(f, `tours/${T}/expenses/e1/revisions/2`), {
        editorUid: 'admin',
        editedAt: serverTimestamp(),
        changedFields: ['deletedAt'],
        before: {},
        after: {},
      });
      await assertFails(b.commit());
      await assertFails(deleteDoc(doc(db('alice'), `tours/${T}/expenses/e1`)));
    });
  });

  test('closed tours block ordinary expense writes', async () => {
    await seed((f) => updateDoc(doc(f, `tours/${T}`), { status: 'closed' }));
    await assertFails(add('alice', expenseDoc()));
    await assertFails(add('host', expenseDoc({ payerUid: 'host', createdBy: 'host' })));
  });
});

describe('settlements', () => {
  beforeEach(() => seedTour());

  const submit = (uid, overrides = {}) =>
    setDoc(doc(db(uid), `tours/${T}/settlements/s1`), {
      fromUid: 'bob',
      toUid: 'admin',
      amountMinor: 100,
      currencyCode: 'BDT',
      status: 'pending_confirmation',
      createdBy: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      ...overrides,
    });

  const confirm = (uid) =>
    updateDoc(doc(db(uid), `tours/${T}/settlements/s1`), {
      status: 'confirmed',
      confirmedBy: uid,
      confirmedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

  test('only a party can submit, with pending status', async () => {
    await assertFails(submit('alice'));
    await assertFails(submit('bob', { status: 'confirmed' }));
    await assertFails(submit('bob', { amountMinor: 0 }));
    await assertFails(submit('bob', { toUid: 'bob' }));
    await assertSucceeds(submit('bob'));
  });

  test('payer cannot confirm their own payment; counterparty can, once', async () => {
    await assertSucceeds(submit('bob'));
    await assertFails(confirm('bob'));
    await assertFails(confirm('alice'));
    await assertFails(confirm('host'));
    await assertSucceeds(confirm('admin'));
    await assertFails(confirm('admin'));
  });

  test('cannot forge another user as confirmer', async () => {
    await assertSucceeds(submit('bob'));
    await assertFails(
      updateDoc(doc(db('bob'), `tours/${T}/settlements/s1`), {
        status: 'confirmed',
        confirmedBy: 'admin',
        confirmedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('dispute by counterparty with reason; amount is immutable', async () => {
    await assertSucceeds(submit('bob'));
    await assertFails(
      updateDoc(doc(db('admin'), `tours/${T}/settlements/s1`), {
        amountMinor: 1,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('admin'), `tours/${T}/settlements/s1`), {
        status: 'disputed',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('admin'), `tours/${T}/settlements/s1`), {
        status: 'disputed',
        disputeReason: 'Not received',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('uninvolved admin confirms only when the counterparty is inactive', async () => {
    await assertSucceeds(submit('bob', { toUid: 'alice' }));
    await assertFails(confirm('admin'));
    await seed((f) => updateDoc(doc(f, `tours/${T}/members/alice`), { status: 'left' }));
    await assertSucceeds(confirm('admin'));
  });

  test('settlements still work in closed tours', async () => {
    await seed((f) => updateDoc(doc(f, `tours/${T}`), { status: 'closed' }));
    await assertSucceeds(submit('bob'));
    await assertSucceeds(confirm('admin'));
  });
});

describe('inbox (server-written)', () => {
  beforeEach(() => seedTour());

  const item = (overrides = {}) => ({
    type: 'settlementSubmitted',
    tourId: T,
    tourName: 'Trip',
    senderUid: 'bob',
    senderName: 'Bob',
    createdAt: serverTimestamp(),
    expiresAt: ts(30 * DAY),
    read: false,
    ...overrides,
  });

  test('no client can create inbox items, not even for themselves', async () => {
    await assertFails(setDoc(doc(db('bob'), 'users/admin/inbox/n1'), item()));
    await assertFails(setDoc(doc(db('admin'), 'users/admin/inbox/n1'), item()));
    await assertFails(setDoc(doc(db('stranger'), 'users/admin/inbox/n1'), item()));
  });

  test('only the recipient reads and marks items read', async () => {
    await seed((f) => setDoc(doc(f, 'users/admin/inbox/n1'), item()));
    await assertSucceeds(getDoc(doc(db('admin'), 'users/admin/inbox/n1')));
    await assertFails(getDoc(doc(db('bob'), 'users/admin/inbox/n1')));
    await assertSucceeds(updateDoc(doc(db('admin'), 'users/admin/inbox/n1'), { read: true }));
    await assertFails(updateDoc(doc(db('admin'), 'users/admin/inbox/n1'), { type: 'joinApproved' }));
    await assertSucceeds(deleteDoc(doc(db('admin'), 'users/admin/inbox/n1')));
  });
});

describe('push devices and preferences', () => {
  const device = (overrides = {}) => ({
    token: 'fcm-token',
    platform: 'android',
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('users manage only their own device tokens', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice/devices/d1'), device()));
    await assertFails(setDoc(doc(db('bob'), 'users/alice/devices/d2'), device()));
    await assertFails(getDoc(doc(db('bob'), 'users/alice/devices/d1')));
    await assertFails(setDoc(doc(db('alice'), 'users/alice/devices/d3'), device({ extra: 1 })));
  });

  test('notification preferences are validated on the profile', async () => {
    const profile = {
      uid: 'alice',
      displayName: 'Alice',
      email: 'alice@example.com',
      locale: 'en',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), profile));
    await assertSucceeds(
      updateDoc(doc(db('alice'), 'users/alice'), {
        notificationPrefs: { important: true, expenses: false, plans: true },
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('alice'), 'users/alice'), {
        notificationPrefs: { important: 'yes' },
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('server bookkeeping is not readable by clients', async () => {
    await assertFails(getDoc(doc(db('alice'), 'serverMeta/mapsUsage-2026-10')));
    await assertFails(getDoc(doc(db('alice'), 'serverEvents/x')));
  });
});

describe('content ownership', () => {
  beforeEach(() => seedTour());

  const activity = (uid, overrides = {}) => ({
    title: 'Beach walk',
    dayKey: '2026-03-14',
    sortOrder: 1024,
    status: 'planned',
    favorite: false,
    createdBy: uid,
    updatedBy: uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('members manage their own plan items; admins manage all', async () => {
    await assertSucceeds(
      setDoc(doc(db('alice'), `tours/${T}/activities/a1`), activity('alice')),
    );
    await assertFails(
      setDoc(doc(db('alice'), `tours/${T}/activities/a2`), activity('bob')),
    );
    await assertFails(deleteDoc(doc(db('bob'), `tours/${T}/activities/a1`)));
    await assertSucceeds(deleteDoc(doc(db('admin'), `tours/${T}/activities/a1`)));
    await assertFails(
      setDoc(
        doc(db('alice'), `tours/${T}/activities/a3`),
        activity('alice', { latitude: 200, longitude: 0 }),
      ),
    );
  });

  test('plan items accept Google place fields', async () => {
    await assertSucceeds(
      setDoc(
        doc(db('alice'), `tours/${T}/activities/g1`),
        activity('alice', {
          placeName: 'Inani Beach',
          address: 'Inani, Ukhia, Bangladesh',
          placeId: 'ChIJabc',
          latitude: 21.2,
          longitude: 92.05,
        }),
      ),
    );
  });

  test('closed tour blocks plan writes', async () => {
    await seed((f) => updateDoc(doc(f, `tours/${T}`), { status: 'closed' }));
    await assertFails(
      setDoc(doc(db('alice'), `tours/${T}/activities/a1`), activity('alice')),
    );
  });

  test('feed events cannot impersonate another actor', async () => {
    const event = (uid, actor) =>
      setDoc(doc(db(uid), `tours/${T}/activityFeed/f1`), {
        type: 'expenseAdded',
        actorUid: actor,
        createdAt: serverTimestamp(),
      });
    await assertFails(event('alice', 'bob'));
    await assertFails(event('stranger', 'stranger'));
    await assertSucceeds(event('alice', 'alice'));
  });
});

describe('app write shapes', () => {
  beforeEach(() => seedTour());

  test('leaving: feed event, status and index in one batch', async () => {
    await seed((f) =>
      setDoc(doc(f, `users/bob/tourMemberships/${T}`), { tourId: T, joinedAt: ts() }),
    );
    const f = db('bob');
    const b = writeBatch(f);
    b.set(doc(f, `tours/${T}/activityFeed/f-leave`), {
      type: 'memberLeft',
      actorUid: 'bob',
      label: 'Bob',
      createdAt: serverTimestamp(),
    });
    b.update(doc(f, `tours/${T}/members/bob`), {
      status: 'left',
      removedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    b.delete(doc(f, `users/bob/tourMemberships/${T}`));
    await assertSucceeds(b.commit());
    await assertFails(getDoc(doc(db('bob'), `tours/${T}`)));
  });

  test('re-admitting a removed member through an approved request', async () => {
    await seed((f) =>
      setDoc(doc(f, `tours/${T}/joinRequests/gone`), {
        uid: 'gone',
        displayNameSnapshot: 'gone',
        status: 'pending',
        attemptCount: 2,
        inviteCode: CODE,
        createdAt: ts(-DAY),
        updatedAt: ts(-1000),
      }),
    );
    const f = db('admin');
    const b = writeBatch(f);
    b.update(doc(f, `tours/${T}/joinRequests/gone`), {
      status: 'approved',
      reviewedBy: 'admin',
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    b.update(doc(f, `tours/${T}/members/gone`), {
      uid: 'gone',
      displayNameSnapshot: 'gone',
      photoUrlSnapshot: null,
      role: 'member',
      status: 'active',
      joinedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      removedAt: null,
    });
    b.set(doc(f, `users/gone/tourMemberships/${T}`), {
      tourId: T,
      joinedAt: serverTimestamp(),
    });
    await assertSucceeds(b.commit());
    await assertSucceeds(getDoc(doc(db('gone'), `tours/${T}`)));
  });

  test('note edit requires the matching revision; others cannot edit', async () => {
    await seed((f) =>
      setDoc(doc(f, `tours/${T}/notes/n1`), {
        body: 'Hotel code 1234',
        createdBy: 'alice',
        updatedBy: 'alice',
        createdAt: ts(-1000),
        updatedAt: ts(-1000),
        revisionCount: 0,
      }),
    );
    const edit = (uid, withRevision) => {
      const f = db(uid);
      const b = writeBatch(f);
      b.update(doc(f, `tours/${T}/notes/n1`), {
        body: 'Hotel code 4321',
        updatedBy: uid,
        updatedAt: serverTimestamp(),
        revisionCount: 1,
      });
      if (withRevision) {
        b.set(doc(f, `tours/${T}/notes/n1/revisions/1`), {
          editorUid: uid,
          editedAt: serverTimestamp(),
          changedFields: ['body'],
          before: { body: 'Hotel code 1234' },
          after: { body: 'Hotel code 4321' },
        });
      }
      return b.commit();
    };
    await assertFails(edit('bob', true));
    await assertFails(edit('alice', false));
    await assertSucceeds(edit('alice', true));
  });

  test('packing: members tick items; label edits need ownership', async () => {
    await seed((f) =>
      setDoc(doc(f, `tours/${T}/packingItems/p1`), {
        label: 'Sunscreen',
        checked: false,
        createdBy: 'alice',
        createdAt: ts(-1000),
        updatedAt: ts(-1000),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('bob'), `tours/${T}/packingItems/p1`), {
        checked: true,
        checkedBy: 'bob',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('bob'), `tours/${T}/packingItems/p1`), {
        label: 'Hacked',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(db('bob'), `tours/${T}/packingItems/p1`)));
  });
});
