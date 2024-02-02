import time
import threading
from typing import Callable


class Model:
    """ Runs a function in a separate thread """
    def __init__(self, func: Callable):
        """
        Constructor
        @In, func, Callable, the function to run
        @Out, None
        """
        self.func = func
        self.thread = None
        self.start_time = None

    def start(self):
        """
        Start the thread
        @In, None
        @Out, None
        """
        self.thread = threading.Thread(target=self.func)
        self.thread.daemon = True
        self.start_time = time.time()
        self.thread.start()

    def get_execution_time(self):
        """
        Get the current execution time of the thread
        @In, None
        @Out, exec_time, float, the execution time in seconds
        """
        if self.start_time is None:
            return 0
        else:
            exec_time = time.time() - self.start_time
            return exec_time

    def is_alive(self):
        """
        Checks if the thread is still running
        @In, None
        @Out, is_alive, bool, True if the thread is still running
        """
        return self.thread.is_alive()
