using System;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.CommandLine
{
    class ConsoleStream : IEventStream
    {
        public void Publish(Event actionEvent)
        {
            switch (actionEvent.Type)
            {
                case EventType.Information:
                    Console.ForegroundColor = ConsoleColor.Gray;
                    break;
                case EventType.Warning:
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    break;
                case EventType.Error:
                    Console.ForegroundColor = ConsoleColor.Red;
                    break;
            }

            Console.WriteLine(actionEvent.Details);
            Console.ResetColor();            
        }
    }
}