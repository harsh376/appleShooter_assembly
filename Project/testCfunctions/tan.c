#include <stdio.h>
#include <math.h>


// struct coord getCoordinates(int x, int y)
// {
// 	struct coord a;
// 	a.x = x;
// 	a.y = abs(y-240);

// 	return a;
// }


void getCoordinates(int x, int y)
{

	int x1 = x;
	int y1 = abs(y-240);

	printf("VGA x,y = %d,%d\n", x1, y1);

}


int getSlope(int theta, int x)
{
	float theta_in_radians = (float)theta/180;
	float slope = tan(theta_in_radians * 3.1415926535897932);

	int y = slope*x;

	return y;
}


void projectile(int v_initial, int theta)
{

	float theta_in_radians = (float)theta/180;

	// printf("theta = %f\n", theta_in_radians);

	int v_x = v_initial*cos(theta_in_radians);
	int v_y = v_initial*sin(theta_in_radians);	

	int x,y;
	int t;
	int f = 1;
	for(t=0; t<300; t++)
	{
		// printf("v_x = %d\n", v_x);
		// x = v_x * t;
		y = (v_y * t) - (0.5*9.81*t*t*0.5);

		if(t==1)
			f=y;


		printf("x,y = %d,%d\n", t, (y/f));
		// getCoordinates(x, y);

		// t = t+0.5;
		// printf("x,y = %d,%d\n", x, y);
	}

}



void proj(int vel, int theta)
{
	int N = 50;
	float g = 9.81;

	float theta_in_radians = (float)theta/180;
	float v_x = vel*cos(theta_in_radians);
	float v_y = vel*sin(theta_in_radians);	


	float ymax = vel*vel*sin(theta_in_radians)*sin(theta_in_radians)/(2*g);

	float tmh = v_y/g;		// time to max height
	float ttotal = 2*tmh;			// total time

	float tinc = ttotal/N; 			// time increment

	float t1 = tinc;
	int i, x, y;
	for(i=0; i<N; i++)
	{
		x = t1*v_x;
		y = t1*v_y-0.5*g*t1*t1;

		printf("%d,%d\n", x, y);
		t1 = t1+tinc; 
	}

	printf("max height = %f\n", ymax);

}




int main(void)
{


	proj(190, 15);

	// projectile(2000, 0);

	// int i;
	// for(i=0; i<10; i++)
	// {
	// 	int y = getSlope(i, 30);
	// 	struct coord b = getCoordinates(i,y);


	// 	printf("convention : %d,%d\t\tVGA : %d,%d\n", i, y, b->x, b->y);
	// }


	// printf("slope = %d\n", getSlope(50));
	

	return 0;
}