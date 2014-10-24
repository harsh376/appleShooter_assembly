#include <math.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>

// extern int INITIALIZE_TIMER();

// void CLEAR_SCREEN();

struct coord{
	int x;
	int y;
};

struct coord getCoordinates(int x, int y)
{
	struct coord a;
	a.x = x;
	a.y = abs(y-240);

	return a;
}


void write_pixel(int x, int y, short colour) 
{
  volatile short *vga_addr=(volatile short*)(0x08000000 + (y<<10) + (x<<1));
  *vga_addr=colour;
}


void draw_c(int x1, int y1) 
{
  int x,y;
  for (x = 0; x < 5; x++) 
  {
    for (y = 0; y < 5; y++) 
    {
	  write_pixel(x+x1,y+y1,0xffff);
	  // INITIALIZE_TIMER();
	}
  }
}

void erase_c(int x1, int y1) 
{
  int x,y;
  for (x = 0; x < 5; x++) 
  {
    for (y = 0; y < 5; y++) 
    {
	  write_pixel(x+x1,y+y1,0x0ef0);
	  // INITIALIZE_TIMER();
	}
  }
}

// struct coord vComp(int vel, int theta)
// {
// 	struct coord a;
// 	a.x = vel*cos(theta_in_radians);
// 	a.y = vel*sin(theta_in_radians);	

// 	return
// }




int proj(int level, int vel, int theta)
{


	int N = 1000;
	float g = 9.81;

	float theta_in_radians = (float)theta/180;
	float v_x = vel*cos(theta_in_radians);
	float v_y = vel*sin(theta_in_radians);	


	float ymax = vel*vel*sin(theta_in_radians)*sin(theta_in_radians)/(2*g);

	float tmh = v_y/g;		// time to max height
	float ttotal = 2*tmh;			// total time

	float tinc = (float)ttotal/N; 			// time increment

	float t1 = tinc;
	int i, x, y, x2, y2;
	
	int p1 =5;
	int p2 = 5;

	int offset = 0;
	if(level==1)
	{
		offset = 200;
	}
	else if(level==2)
	{
		offset = 150;
	}
	else if(level==3)
	{
		offset = 50;
	}

	int collision = 0;
	int b_left = 300;
	int b_right = 305;
	int b_top = 150;
	int b_bottom = 155;

	int c_left = 300;
	int c_right = 320;
	int c_top = 156;
	int c_bottom = 208;


	for(i=0; i<N && !collision; i++)
	{
		x = t1*v_x;
		y = t1*v_y-0.5*g*t1*t1;
		int x1 = x + offset;
		int y1 = abs(y-240) - 50;


    // A's Left Edge to left of B's right edge, and
    // A's right edge to right of B's left edge, and
    // A's top above B's bottom, and
    // A's bottom below B's Top
		int a_left = x1;
		int a_right = x1+5;
		int a_top = y1;
		int a_bottom = y1+5;


		if(a_left<=b_right && a_right>=b_left && a_top<=b_bottom && a_bottom>=b_top)
		{
			collision = 1;
		}


		else if(a_left<=c_right && a_right>=c_left && a_top<=c_bottom && a_bottom>=c_top)
		{
			collision = 2;
		}

		else if(x>0 && x<319 && y>0 && y<239)
		{
			// draw_c(x, abs(y-240));

			// UNIT(1, x1, y1);

			// int a = 9;


			PLOT_5x5_SQUARE(0xffff, x1, y1, 0x5);

			INITIALIZE_TIMER();

			PLOT_5x5_SQUARE(0x0000, x1, y1, 0x5);

			INITIALIZE_TIMER();

			if(i%2==0)
			{
				PLOT_5x5_SQUARE(0x0000, x1, y1, 0x1);
			}
	
			else
			{
				PLOT_5x5_SQUARE(0xfcc0, x1, y1, 0x1);
			}

			INITIALIZE_TIMER();

			// erase_c(x1, abs(y1));			
		}
		t1 = t1+tinc; 
	}

	return collision;



}



