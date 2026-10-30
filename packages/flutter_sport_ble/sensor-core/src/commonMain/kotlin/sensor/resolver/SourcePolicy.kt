package sensor.resolver

import sensor.model.Capability
import sensor.model.MetricType

/**
 * The default preference between sources of one metric, from what each device really is. LOWER is better. The user's own choice
 * (`setPreferred`) always wins over it. Starting values chosen by reasoning, not measured.
 *
 *  - Heart rate: a heart rate sensor before a machine that also reports one.
 *  - Running speed, cadence, stride: a running footpod before a machine.
 *  - Cycling cadence: a power meter before a cadence sensor before a trainer. Cycling speed: a wheel sensor before a trainer.
 *  - Power: a power meter before a trainer or a rower.
 *  - Everything else: no preference (the source chosen first stays).
 */
object SourcePolicy {
    fun rank(metric: MetricType, capabilities: Set<Capability>): Int = when (metric) {
        MetricType.HEART_RATE -> if (Capability.HEART_RATE in capabilities) 0 else 1
        MetricType.RUNNING_SPEED, MetricType.RUNNING_CADENCE, MetricType.RUNNING_STRIDE_LENGTH ->
            if (Capability.RUNNING_SPEED_CADENCE in capabilities) 0 else 1
        MetricType.CYCLING_CADENCE -> when {
            Capability.CYCLING_POWER in capabilities -> 0
            Capability.CYCLING_SPEED_CADENCE in capabilities -> 1
            else -> 2
        }
        MetricType.CYCLING_SPEED -> if (Capability.CYCLING_SPEED_CADENCE in capabilities) 0 else 1
        MetricType.POWER_WATTS -> if (Capability.CYCLING_POWER in capabilities) 0 else 1
        else -> 0
    }
}
