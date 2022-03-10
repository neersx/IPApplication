using System.Threading.Tasks;
using InprotechKaizen.Model.Names;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public interface INameConsolidator
    {
        string Name { get; }

        Task Consolidate(Name to, Name from, ConsolidationOption option);
    }
}