#!/bin/bash

declare -A ht_capab=(
    # L450 e.g.
    intel_7265="[HT40-][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40][DSSS_CCK-40][DSSS_CCK-40]"
    
    # fuksiläppärissä
    intel_ax201="[HT40+][LDPC][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][DSSS_CCK-40][MAX-AMSDU-7935]"
)

declare -A vht_capab=(
    # fuksiläppärissä
    intel_ax201="[MAX-MPDU-11454][VHT160][RXLDPC][SHORT-GI-80][SHORT-GI-160][TX-STBC-2BY1][RX-STBC-1][SU-BEAMFORMEE][MU-BEAMFORMEE]"
)

# fuksiläppäri ensisijäisesti
NIC=${1:-intel_ax201}

sudo create_ap --freq-band 5 -c 149 --country FI \
--ieee80211n --ht_capab "${ht_capab[$NIC]}" \
--ieee80211ac --vht_capab "${vht_capab[$NIC]}" \
wlp0s20f3 enp0s20f0u1u3 tomjtoth qwer1234.5678

