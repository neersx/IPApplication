using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Names.Consolidation
{
    public interface ISingleNameConsolidation
    {
        Task Consolidate(int executeAs, int from, int to, bool keepAddressHistory, bool keepTelecomHistory, bool keepConsolidatedName);
    }
}