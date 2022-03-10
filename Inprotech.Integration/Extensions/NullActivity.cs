using System.Threading.Tasks;
using Dependable;

namespace Inprotech.Integration.Extensions
{
    public class NullActivity
    {
        public Task NoOperation()
        {
            return Task.FromResult<string>(null);
        }
    }

    public static class DefaultActivity
    {
        public static Activity NoOperation()
        {
            return Activity.Run<NullActivity>(n => n.NoOperation());
        }
    }
}