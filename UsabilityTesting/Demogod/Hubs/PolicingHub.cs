using Demogod.Policing;
using Microsoft.AspNet.SignalR;

namespace Demogod.Hubs
{
    public class PolicingHub : Hub
    {
        readonly ServerManager _serverManager = new ServerManager();

        public void TurnOn()
        {
            _serverManager.TurnOn();
        }

        public void TurnOff()
        {
            _serverManager.TurnOff();
        }

        public void MakeFailedItems()
        {
            _serverManager.MakeFailedItems();
        }

        public void MakeErrorItems()
        {
            _serverManager.MakeErrorItems();
        }

        public void MakeMoreItems()
        {
            _serverManager.MakeMoreItems();
        }

        public void ClearAllItems()
        {
            _serverManager.ClearAllItems();
        }
    }
}