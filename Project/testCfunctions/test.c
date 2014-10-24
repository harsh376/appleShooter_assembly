struct coord{
	int x;
	int y;
};


struct coord addNum(int a, int b)
{
	struct coord a1;
	a1.x = 4;
	a1.y = 5;

	return a1;
}


int main()
{

	struct coord* b = addNum(3,4);

	printf("%d\n", b->x);
	printf("%d\n", b->y);

	return 0;
}