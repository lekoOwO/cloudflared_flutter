package mobile

import (
	"strings"
	"testing"

	"github.com/cloudflare/cloudflared/connection"
)

func TestBuildLocalIngressUsesOriginURL(t *testing.T) {
	const originURL = "http://127.0.0.1:43123"

	ingressRules, err := buildLocalIngress(originURL)
	if err != nil {
		t.Fatalf("buildLocalIngress returned error: %v", err)
	}
	if len(ingressRules.Rules) != 1 {
		t.Fatalf("expected one ingress rule, got %d", len(ingressRules.Rules))
	}
	if got := ingressRules.Rules[0].Service.String(); got != originURL {
		t.Fatalf("expected ingress service %q, got %q", originURL, got)
	}
}

func TestBuildLocalIngressRejectsEmptyOriginURL(t *testing.T) {
	_, err := buildLocalIngress("")
	if err == nil {
		t.Fatal("expected an error for empty originURL")
	}
	if !strings.Contains(err.Error(), "originURL is required") {
		t.Fatalf("expected originURL error, got %v", err)
	}
}

func TestNewTunnelWithOptionsForcesQuickTunnelToSingleHAConnection(t *testing.T) {
	tunnel, err := NewTunnelWithOptions(
		"test-token",
		"http://127.0.0.1:43123",
		"https://random.trycloudflare.com/pair/code",
		4,
		true,
		nil,
	)
	if err != nil {
		t.Fatalf("NewTunnelWithOptions returned error: %v", err)
	}

	if tunnel.config.QuickTunnelURL != "random.trycloudflare.com" {
		t.Fatalf("quick tunnel URL not stored: %q", tunnel.config.QuickTunnelURL)
	}
	if tunnel.config.HAConnections != 1 {
		t.Fatalf("quick tunnel HA connections = %d, want 1", tunnel.config.HAConnections)
	}
	if !tunnel.config.EnablePostQuantum {
		t.Fatal("enablePostQuantum was not stored in tunnel config")
	}
}

func TestNewTunnelWithOptionsDefaultsNamedTunnelToFourConnections(t *testing.T) {
	tunnel, err := NewTunnelWithOptions(
		"test-token",
		"http://127.0.0.1:43123",
		"",
		0,
		false,
		nil,
	)
	if err != nil {
		t.Fatalf("NewTunnelWithOptions returned error: %v", err)
	}

	if tunnel.config.HAConnections != 4 {
		t.Fatalf("named tunnel HA connections = %d, want 4", tunnel.config.HAConnections)
	}
}

func TestTunnelPropertiesIncludeQuickTunnelURL(t *testing.T) {
	props := newTunnelProperties(connection.Credentials{}, "random.trycloudflare.com")
	if props.QuickTunnelUrl != "random.trycloudflare.com" {
		t.Fatalf("QuickTunnelUrl = %q, want random.trycloudflare.com", props.QuickTunnelUrl)
	}
}
