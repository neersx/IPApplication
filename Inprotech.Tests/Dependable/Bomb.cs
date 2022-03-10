namespace Inprotech.Tests.Dependable
{
    public class Bomb
    {
        public bool IsSet { get; private set; }

        public void It()
        {
            IsSet = true;
        }
    }
}