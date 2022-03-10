using System;
using System.Threading.Tasks;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public interface ICleanUpFolders
    {
        Task Clean(Guid sessionGuid, string rootSessionPath);
    }
}