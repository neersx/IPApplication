using Caliburn.Micro;

namespace Inprotech.Setup
{
    public interface IShell
    {
        void ShowHome();

        void ShowScreen(IScreen screen);
    }
}