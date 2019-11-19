extern void GPIO_init();
extern void max7219_init();
extern void max7219_send(int addr, int data);

const int max7219_max_size = 8;

int display(int data, int num_digs) {
    if (num_digs > max7219_max_size || num_digs < 0) return -1;
    int i = 0;
    for (; i < num_digs ; i++, data /= 10)
        max7219_send(i + 1, data % 10);
    for (; i < max7219_max_size ; i++)
        max7219_send(i + 1, 0xF);
    return 0;
}

int main() {
    int student_id = 616014;
    GPIO_init();
    max7219_init();
    display(student_id, 7);
    return 0;
}
