using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.Integration.IPPlatform.FileApp.Post
{
    public interface IPostInstructionCreationTasks
    {
        Task Perform(FileSettings fileSettings, FileCase fileCase);
    }
}
