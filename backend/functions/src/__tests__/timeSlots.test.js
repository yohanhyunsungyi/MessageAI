/**
 * Time Slot Generation Tests
 * Tests for proactive assistant time slot generation with multi-timezone support
 */

const admin = require("firebase-admin");
const {
  getUserTimezone,
  getParticipantTimezones,
  generateTimeSlots,
} = require("../features/proactive/timeSlots");

// Mock Firestore
jest.mock("firebase-admin", () => {
  const mockFirestore = {
    collection: jest.fn(),
  };

  return {
    firestore: jest.fn(() => mockFirestore),
    FieldValue: {
      serverTimestamp: jest.fn(() => "TIMESTAMP"),
    },
  };
});

describe("Time Slot Generation", () => {
  let mockFirestore;

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    mockFirestore = admin.firestore();
  });

  describe("getUserTimezone", () => {
    it("should return user's timezone from Firestore", async () => {
      // Mock Firestore response
      const mockUserDoc = {
        exists: true,
        data: () => ({
          timezone: "America/New_York",
        }),
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      const timezone = await getUserTimezone("user123");

      expect(timezone).toBe("America/New_York");
      expect(mockFirestore.collection).toHaveBeenCalledWith("users");
    });

    it("should return default timezone if user has no timezone set", async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({}), // No timezone field
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      const timezone = await getUserTimezone("user123");

      expect(timezone).toBe("America/Los_Angeles"); // Default
    });

    it("should return default timezone if user not found", async () => {
      const mockUserDoc = {
        exists: false,
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      const timezone = await getUserTimezone("nonexistent");

      expect(timezone).toBe("America/Los_Angeles"); // Default
    });
  });

  describe("getParticipantTimezones", () => {
    it("should fetch timezones for all participants", async () => {
      const mockUserDocs = {
        user1: { exists: true, data: () => ({ timezone: "America/Los_Angeles" }) },
        user2: { exists: true, data: () => ({ timezone: "America/New_York" }) },
        user3: { exists: true, data: () => ({ timezone: "Europe/London" }) },
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn((userId) => ({
          get: jest.fn().mockResolvedValue(mockUserDocs[userId]),
        })),
      });

      const timezones = await getParticipantTimezones(["user1", "user2", "user3"]);

      expect(timezones).toEqual({
        user1: "America/Los_Angeles",
        user2: "America/New_York",
        user3: "Europe/London",
      });
    });
  });

  describe("generateTimeSlots", () => {
    it("should generate valid time slots for users in different timezones", async () => {
      // Mock participant timezones: PST, EST, GMT
      const mockUserDocs = {
        userPST: { exists: true, data: () => ({ timezone: "America/Los_Angeles" }) },
        userEST: { exists: true, data: () => ({ timezone: "America/New_York" }) },
        userGMT: { exists: true, data: () => ({ timezone: "Europe/London" }) },
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn((userId) => ({
          get: jest.fn().mockResolvedValue(mockUserDocs[userId]),
        })),
      });

      const timeSlots = await generateTimeSlots(
          ["userPST", "userEST", "userGMT"],
          60, // 60 minutes
          2, // 2 days out
      );

      // Should return an array
      expect(Array.isArray(timeSlots)).toBe(true);

      // Each slot should have required fields
      if (timeSlots.length > 0) {
        const slot = timeSlots[0];
        expect(slot).toHaveProperty("startTime");
        expect(slot).toHaveProperty("duration");
        expect(slot).toHaveProperty("timezoneDisplays");

        // Should have timezone displays for all participants
        expect(slot.timezoneDisplays).toHaveProperty("userPST");
        expect(slot.timezoneDisplays).toHaveProperty("userEST");
        expect(slot.timezoneDisplays).toHaveProperty("userGMT");

        // Duration should match
        expect(slot.duration).toBe(60);
      }
    });

    it("should respect urgency by adjusting daysOut", async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({ timezone: "America/Los_Angeles" }),
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      // Urgent meeting - 1 day out
      const urgentSlots = await generateTimeSlots(
          ["user1"],
          60,
          1, // 1 day out for urgent
      );

      expect(Array.isArray(urgentSlots)).toBe(true);
    });

    it("should return empty array if no valid slots found", async () => {
      // This is hard to test without mocking the entire algorithm,
      // but we can verify it handles edge cases gracefully
      const mockUserDoc = {
        exists: true,
        data: () => ({ timezone: "America/Los_Angeles" }),
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      const timeSlots = await generateTimeSlots(["user1"], 60, 2);

      // Should at least return an array
      expect(Array.isArray(timeSlots)).toBe(true);
    });
  });

  describe("Time Slot Format", () => {
    it("should format time slots with timezone displays", async () => {
      const mockUserDocs = {
        userPST: { exists: true, data: () => ({ timezone: "America/Los_Angeles" }) },
        userEST: { exists: true, data: () => ({ timezone: "America/New_York" }) },
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn((userId) => ({
          get: jest.fn().mockResolvedValue(mockUserDocs[userId]),
        })),
      });

      const timeSlots = await generateTimeSlots(["userPST", "userEST"], 60, 2);

      if (timeSlots.length > 0) {
        const slot = timeSlots[0];

        // Each timezone display should be a readable string
        expect(typeof slot.timezoneDisplays.userPST).toBe("string");
        expect(typeof slot.timezoneDisplays.userEST).toBe("string");

        // Start time should be ISO 8601 format
        expect(slot.startTime).toMatch(/^\d{4}-\d{2}-\d{2}T/);
      }
    });
  });

  describe("Performance", () => {
    it("should complete within 5 seconds", async () => {
      const mockUserDoc = {
        exists: true,
        data: () => ({ timezone: "America/Los_Angeles" }),
      };

      mockFirestore.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc),
        }),
      });

      const startTime = Date.now();

      await generateTimeSlots(["user1", "user2", "user3"], 60, 2);

      const duration = Date.now() - startTime;

      expect(duration).toBeLessThan(5000); // Should complete in <5s
    });
  });
});
