import { describe, it, expect, vi, beforeEach } from "vitest";
import { getImageFromDatabase } from "../image.controller.js";
import { Image } from "../../models/image.model.js";

// Mock the Image model
vi.mock("../../models/image.model.js", async (importOriginal) => {
  const actual = await importOriginal();
  return {
    ...actual,
    Image: {
      ...actual.Image,
      aggregate: vi.fn(),
      aggregatePaginate: vi.fn(),
    },
  };
});

describe("getImageFromDatabase", () => {
  let mockReq;
  let mockRes;

  beforeEach(() => {
    vi.clearAllMocks();

    mockReq = {
      user: { _id: "user123" },
      query: {},
    };

    mockRes = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn(),
    };
  });

  it("should pass ApiError to next if user is not found in request", async () => {
    mockReq.user = undefined;
    const nextMock = vi.fn();
    
    await getImageFromDatabase(mockReq, mockRes, nextMock);

    expect(nextMock).toHaveBeenCalled();
    const errorPassed = nextMock.mock.calls[0][0];
    expect(errorPassed.statusCode).toBe(404);
    expect(errorPassed.message).toBe("User not found");
  });

  it("should apply default pagination (page=1, limit=10)", async () => {
    Image.aggregate.mockReturnValue("mock_aggregate_object");
    Image.aggregatePaginate.mockResolvedValue({
      docs: [{ id: "img1" }],
      page: 1,
      limit: 10,
      totalPages: 1,
      totalDocs: 1,
    });

    await getImageFromDatabase(mockReq, mockRes, vi.fn());

    expect(Image.aggregate).toHaveBeenCalled();
    expect(Image.aggregatePaginate).toHaveBeenCalledWith(
      "mock_aggregate_object",
      { page: 1, limit: 10 }
    );

    expect(mockRes.status).toHaveBeenCalledWith(200);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 200,
        message: "Images retrieved successfully",
      })
    );
  });

  it("should apply custom pagination from query parameters", async () => {
    mockReq.query = { page: "2", limit: "5" };

    Image.aggregate.mockReturnValue("mock_aggregate_object");
    Image.aggregatePaginate.mockResolvedValue({
      docs: [],
      page: 2,
      limit: 5,
      totalPages: 3,
      totalDocs: 15,
    });

    await getImageFromDatabase(mockReq, mockRes, vi.fn());

    expect(Image.aggregatePaginate).toHaveBeenCalledWith(
      "mock_aggregate_object",
      { page: 2, limit: 5 }
    );

    expect(mockRes.status).toHaveBeenCalledWith(200);
  });
});
