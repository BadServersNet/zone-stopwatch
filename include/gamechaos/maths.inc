
#if defined _gamechaos_stocks_maths_included
	#endinput
#endif
#define _gamechaos_stocks_maths_included

#include <gamechaos/vectors>

/**
 * Credit: https://stackoverflow.com/questions/5666222/3d-line-plane-intersection
 * Determines the point of intersection between a plane defined by a point and a normal vector and a line defined by a point and a direction vector.
 *
 * @param planePoint    A point on the plane.
 * @param planeNormal   Normal vector of the plane.
 * @param linePoint     A point on the line.
 * @param lineDirection Direction vector of the line.
 * @param result		Resultant vector.
 */
stock void lineIntersection(const float planePoint[3], const float planeNormal[3], const float linePoint[3], const float lineDirection[3], float result[3])
{
	if (GetVectorDotProduct(planeNormal, lineDirection) == 0)
	{
		return;
	}
	
	float t = (GetVectorDotProduct(planeNormal, planePoint)
			 - GetVectorDotProduct(planeNormal, linePoint))
			 / GetVectorDotProduct(planeNormal, lineDirection);
	
	float lineDir[3];
	CopyVector(lineDirection, lineDir);
	NormalizeVector(lineDir, lineDir);
	
	ScaleVector(lineDir, t);
	
	AddVectors(linePoint, lineDirection, result);
}

/**
 * Calculates a point according to angles supplied that is a certain distance away.
 *
 * @param client			Client index.
 * @param result			Resultant vector.
 * @param distance			Maximum distance to trace.
 * @return 					True on success, false otherwise.
 */
stock bool CalcPointAngleDistance(int client, const float start[3], const float angle[3], float result[3], float distance)
{
	float endpoint[3];
	float zsine = Sine(DegToRad(-angle[0]));
	float zcos = Cosine(DegToRad(-angle[0]));
	
	endpoint[0] = Cosine(DegToRad(angle[1])) * zcos;
	endpoint[1] = Sine(DegToRad(angle[1])) * zcos;
	endpoint[2] = zsine;
	
	ScaleVector(endpoint, distance);
	AddVectors(start, endpoint, endpoint);
	
	TR_TraceRayFilter(start, endpoint, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer, client);
	
	if (TR_DidHit())
	{
		TR_GetEndPosition(result);
		return true;
	}
	
	CopyVector(endpoint, result);
	return false;
}

/**
 * Compares how close 2 floats are.
 *
 * @param z1				Float 1
 * @param z2				Float 2
 * @param tolerance			How close the floats have to be to return true.
 * @return 					True on success, false otherwise.
 */
stock bool IsRoughlyEqual(float z1, float z2, float tolerance)
{
	return IsFloatInRange(z1 - z2, -tolerance, tolerance);
}

/**
 * Checks if a float is within a range
 *
 * @param number			Float to check.
 * @param min				Minimum range.
 * @param max				Maximum range.
 * @return 					True on success, false otherwise.
 */
stock bool IsFloatInRange(float number, float min, float max)
{
	return number >= min && number <= max;
}

/**
 * Checks if a float is within a lower bound.
 *
 * @param z1				Float 1.
 * @param z2				Float 2.
 * @param tolerance			Size of lower bound.
 * @return 					True if success, false otherwise.
 */
stock bool IsFailstat(float z1, float z2, float tolerance)
{
	return z1 < z2 && z1 > z2 - tolerance;
}

/**
 * Keeps the yaw angle within the range of -180 to 180.
 *
 * @param angle				Angle.
 * @return 					Normalised angle.
 */
public float NormaliseAngle(float angle)
{
	while (angle <= -180.0)
	{
		angle += 360.0;
	}
	
	while (angle > 180.0)
	{
		angle -= 360.0;
	}
	
	return angle;
}

/**
 * Linearly interpolates between 2 values.
 *
 * @param f1				Float 1.
 * @param f2				Float 2.
 * @param fraction			Amount to interpolate.
 * @return 					Interpolated value.
 */
stock float InterpLinear(float f1, float f2, float fraction)
{
	float diff = f1 - f2;
	
	return diff * fraction + f2;
}

/**
 * Calculates the linear fraction from a value that was interpolated and 2 values it was interpolated from.
 *
 * @param f1				Float 1.
 * @param f2				Float 2.
 * @param fraction			Interpolated value.
 * @return 					Fraction.
 */
stock float CalcLerpFraction(float f1, float f2, float lerped)
{
	float diff = f1 - f2;
	
	float fraction = lerped - f2 / diff;
}

/**
 * Calculate absolute value of an integer.
 *
 * @param x					Integer.
 * @return 					Absolute value of integer.
 */
stock int abs(x)
{
   return x >= 0 ? x : -x;
}

/**
 * Checks if an integer is within a range
 *
 * @param number			Integer to check.
 * @param min				Minimum range.
 * @param max				Maximum range.
 * @return 					True on success, false otherwise.
 */
stock bool IsIntInRange(int number, int min, int max)
{
	return number >= min && number <= max;
}

/**
 * Calculates a float percentage from a common fraction.
 *
 * @param numerator			Numerator.
 * @param denominator		Denominator.
 * @return 					Float percentage. -1.0 on failure.
 */
stock float CalcIntPercentage(int numerator, int denominator)
{
	if (denominator == 0)
	{
		return -1.0;
	}
	
	return float(numerator) / float(denominator) * 100.0;
}